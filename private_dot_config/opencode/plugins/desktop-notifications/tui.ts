import { Plugin } from "@opencode/plugin/tui"
import net from "node:net"
import { notificationFor, belongsToClient, type Notification } from "./events"

function send(path: string, notification: Notification): Promise<void> {
  return new Promise((resolve, reject) => {
    const client = net.createConnection(path)
    const timeout = setTimeout(() => {
      client.destroy()
      reject(new Error("Notification bridge timed out"))
    }, 3000)
    const finish = () => {
      clearTimeout(timeout)
      client.destroy()
    }
    let response = ""
    client.on("connect", () => client.write(`${JSON.stringify(notification)}\n`))
    client.on("data", chunk => {
      response += chunk.toString()
      if (!response.includes("\n")) return
      finish()
      try {
        const result = JSON.parse(response.split("\n")[0])
        if (!result.ok) reject(new Error(result.error ?? "Desktop notification failed"))
        else resolve()
      } catch (error) {
        reject(error)
      }
    })
    client.on("error", error => { finish(); reject(error) })
    client.on("end", () => {
      if (!response.includes("\n")) { finish(); reject(new Error("Notification bridge closed")) }
    })
  })
}

export default Plugin.define({
  id: "local.desktop-notifications",
  setup(context) {
    const runtime = process.env.XDG_RUNTIME_DIR ?? `/run/user/${process.getuid?.() ?? 1000}`
    const path = process.env.OPENCODE_NOTIFY_SOCKET ?? `${runtime}/opencode-notify/notify.sock`
    const pending = new Set<ReturnType<typeof setTimeout>>()
    let disposed = false
    let warned = false
    const unsubscribe = context.data.listen(({ details: event }) => {
      const notification = notificationFor(event)
      if (!notification) return
      const route = context.ui.router.current()
      const roots = context.ui.tabs.list().map(tab => tab.sessionID)
      if (route.type === "session") roots.push(route.sessionID)
      if (!belongsToClient(notification.sessionID, roots, id => context.data.session.root(id))) return
      const session = context.data.session.get(notification.sessionID)
      notification.title = session?.title ?? "OpenCode"
      // A short delay prevents flashes of transient permission/question state.
      const timer = setTimeout(() => {
        pending.delete(timer)
        if (disposed) return
        if (event.type === "permission.asked") {
          const requests = context.data.session.permission.list(notification.sessionID)
          if (requests && !requests.some(request => request.id === event.data.id)) return
        }
        if (event.type === "form.created") {
          const forms = context.data.session.form.list(notification.sessionID, context.location)
          if (forms && !forms.some(form => form.id === event.data.form.id)) return
        }
        void send(path, notification).catch(() => {
          if (warned || disposed) return
          warned = true
          context.ui.toast.show({
            title: "Desktop notifications",
            message: "Host bridge unavailable. Start: systemctl --user start opencode-notify.service",
            variant: "warning",
          })
        })
      }, notification.event === "ask" ? 500 : 100)
      pending.add(timer)
    })
    return () => {
      disposed = true
      unsubscribe()
      for (const timer of pending) clearTimeout(timer)
    }
  },
})
