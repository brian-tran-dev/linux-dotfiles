import { describe, expect, test } from "bun:test"
import { belongsToClient, notificationFor } from "./events"

describe("desktop notification events", () => {
  test("permission and question requests map to ask", () => {
    expect(notificationFor({ id: "e1", type: "permission.asked", data: { id: "p1", sessionID: "s1" } })?.event).toBe("ask")
    expect(notificationFor({ id: "e2", type: "form.created", data: { form: { id: "f1", sessionID: "s1" } } })?.event).toBe("ask")
  })
  test("successful and failed executions have distinct sounds", () => {
    expect(notificationFor({ id: "e3", type: "session.execution.succeeded", data: { sessionID: "s1" } })?.event).toBe("done")
    const failed = notificationFor({ id: "e4", type: "session.execution.failed", data: { sessionID: "s1", error: { response: "secret" } } })
    expect(failed?.event).toBe("error")
    expect(JSON.stringify(failed)).not.toContain("secret")
  })
  test("interrupts, working and arbitrary events are silent", () => {
    for (const type of ["session.execution.interrupted", "session.execution.started", "session.updated"])
      expect(notificationFor({ type, data: { sessionID: "s1" } })).toBeUndefined()
  })
  test("event ids enable deduplication across multiple TUIs", () => {
    const event = { id: "event-id", type: "session.execution.succeeded", data: { sessionID: "s1" } }
    expect(notificationFor(event)?.key).toBe("session.execution.succeeded:event-id")
  })
  test("selected and background session tabs are included, unrelated sessions are not", () => {
    const root = (id: string) => id === "child" ? "first" : id
    expect(belongsToClient("first", ["first", "second"], root)).toBe(true)
    expect(belongsToClient("second", ["first", "second"], root)).toBe(true)
    expect(belongsToClient("child", ["first", "second"], root)).toBe(true)
    expect(belongsToClient("other", ["first", "second"], root)).toBe(false)
  })
})
