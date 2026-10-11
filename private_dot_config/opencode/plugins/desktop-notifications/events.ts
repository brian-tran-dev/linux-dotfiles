export type Notification = {
  event: "ask" | "done" | "error"
  key: string
  sessionID: string
  title: string
  message: string
}

// Accept only real lifecycle events, never infer errors from a generic blocked
// state or send prompt/provider-response contents to the desktop.
export function notificationFor(event: any): Notification | undefined {
  const data = event.data
  if (!data) return
  const sessionID = event.type === "form.created" ? data.form?.sessionID : data.sessionID
  if (typeof sessionID !== "string") return
  let kind: Notification["event"]
  let message: string
  switch (event.type) {
    case "permission.asked":
      kind = "ask"
      message = "Permission requested."
      break
    case "form.created":
      kind = "ask"
      message = "An answer is needed."
      break
    case "session.execution.succeeded":
      kind = "done"
      message = "Agent finished."
      break
    case "session.execution.failed":
      kind = "error"
      message = "Agent execution failed."
      break
    default:
      return
  }
  const id = event.id ?? data.id ?? data.form?.id ?? `${sessionID}:${event.created}`
  return { event: kind, key: `${event.type}:${id}`, sessionID, title: "OpenCode", message }
}

export function belongsToClient(sessionID: string, roots: string[], rootOf: (id: string) => string) {
  return roots.some(root => root === sessionID || rootOf(root) === rootOf(sessionID))
}
