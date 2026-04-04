import assert from "node:assert/strict";
import { createRequire } from "node:module";
import path from "node:path";

const require = createRequire(import.meta.url);
const matcher = require(path.resolve("Modules/Bar/Widgets/Workspace/WorkspaceWindowMatcher.js"));

assert.equal(typeof matcher.workspaceMatchesWindow, "function", "Expected workspaceMatchesWindow helper to exist.");

assert.equal(
  matcher.workspaceMatchesWindow({ workspaceId: "2", workspaceName: "2" }, 2, "2"),
  true,
  "Expected numeric workspace ids to match string window workspace ids."
);

assert.equal(
  matcher.workspaceMatchesWindow({ workspaceId: 4, workspaceName: "four" }, "4", "4"),
  true,
  "Expected string workspace ids to match numeric window workspace ids."
);

assert.equal(
  matcher.workspaceMatchesWindow({ workspaceId: "special:scratch", workspaceName: "special:scratch" }, "", "special:scratch"),
  true,
  "Expected scratchpad workspace names to match by workspaceName."
);

assert.equal(
  matcher.workspaceMatchesWindow({ workspaceId: 1, workspaceName: "1" }, 3, "3"),
  false,
  "Expected unrelated workspaces not to match."
);
