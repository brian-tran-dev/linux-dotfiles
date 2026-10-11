import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location("local_links", Path(__file__).with_name("local-links.py"))
links = importlib.util.module_from_spec(spec)
spec.loader.exec_module(links)


class Mark:
    def __init__(self, index, start, end, text, groupdict):
        self.index, self.start, self.end = index, start, end
        self.text, self.groupdict = text, groupdict


class LinksTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root / "main.rs").write_text("test")
        (self.root / "file with spaces.py").write_text("test")
        (self.root / "src").mkdir()
        (self.root / "src/app.ts").write_text("test")

    def tearDown(self):
        self.temp.cleanup()

    def marks(self, text):
        with patch.object(links, "_cwd_candidates", return_value=[str(self.root)]):
            return list(links.mark(text, None, Mark, []))

    def urls(self, text):
        return [m.groupdict["url"] for m in self.marks(text) if m.groupdict["kind"] == "url"]

    def test_url_is_not_rewritten_with_www(self):
        self.assertEqual(self.urls("example.com"), ["https://example.com"])

    def test_localhost_defaults_to_http(self):
        self.assertEqual(self.urls("localhost:3000"), ["http://localhost:3000"])
        self.assertEqual(self.urls("0.0.0.0:5173"), ["http://127.0.0.1:5173"])
        self.assertEqual(self.urls("[::1]:3000"), ["http://[::1]:3000"])

    def test_explicit_https_and_query_are_preserved(self):
        self.assertEqual(self.urls("https://localhost:8443/?x=1!"), ["https://localhost:8443/?x=1!"])
        self.assertEqual(self.urls("HTTP://LOCALHOST:3000/path"), ["HTTP://LOCALHOST:3000/path"])

    def test_parentheses_and_trailing_punctuation(self):
        self.assertEqual(self.urls("(https://example.com/foo)."), ["https://example.com/foo"])
        self.assertEqual(self.urls("https://example.com/a_(b)"), ["https://example.com/a_(b)"])
        self.assertEqual(self.urls("[https://example.com/foo)]."), ["https://example.com/foo"])

    def test_existing_basename_is_file_not_domain(self):
        marks = self.marks("main.rs:12:3")
        self.assertEqual(len(marks), 1)
        self.assertEqual(marks[0].groupdict["fs_path"], str(self.root / "main.rs"))
        self.assertEqual(marks[0].groupdict["line"], 12)
        self.assertEqual(marks[0].groupdict["col"], 3)

    def test_relative_paths_and_quoted_spaces(self):
        for text, filename in [("./src/app.ts:4", "src/app.ts"), ('"file with spaces.py":2', "file with spaces.py")]:
            marks = self.marks(text)
            self.assertEqual(len(marks), 1)
            self.assertEqual(marks[0].groupdict["fs_path"], str(self.root / filename))

    def test_file_uri(self):
        marks = self.marks((self.root / "file with spaces.py").as_uri())
        self.assertEqual(marks[0].groupdict["fs_path"], str(self.root / "file with spaces.py"))

    def test_url_path_is_not_matched_as_file(self):
        url = "https://example.com" + str(self.root / "main.rs")
        self.assertEqual(self.urls(url), [url])
        self.assertEqual(len(self.marks(url)), 1)

    def test_invalid_ip_and_version_are_not_urls(self):
        self.assertEqual(self.urls("999.999.999.999:80 3.13.11"), [])

    def test_soft_wrapped_url_retains_highlight_offsets(self):
        text = "https://example.com/abc\0\0\rdef"
        marks = self.marks(text)
        self.assertEqual(marks[0].groupdict["url"], "https://example.com/abcdef")
        self.assertEqual((marks[0].start, marks[0].end), (0, len(text)))

    def test_selected_url_opens_in_browser(self):
        class Boss:
            def open_url(self, url, cwd=None):
                self.opened = (url, cwd)
        boss = Boss()
        data = {"match": ["localhost:3000"], "groupdicts": [{"kind": "url", "url": "http://localhost:3000"}], "cwd": str(self.root)}
        links.handle_result(None, data, 1, boss, [])
        self.assertEqual(boss.opened, ("http://localhost:3000", str(self.root)))

    def test_herdr_foreground_podman_workdir_is_preferred(self):
        project = self.root / "project"
        project.mkdir()
        with patch.object(links, "_window_info", return_value={
            "cwd": str(self.root), "foreground_processes": [{"cmdline": ["herdr"]}],
        }), patch.object(links, "_herdr_pane", return_value={"pane_id": "w1:p1", "cwd": str(self.root)}), patch.object(links, "_run_json", return_value={
            "result": {"process_info": {"foreground_processes": [{"argv": ["podman", "run", "--workdir", str(project)]}]}},
        }):
            self.assertEqual(links._cwd_candidates()[0], str(project))


if __name__ == "__main__":
    unittest.main()
