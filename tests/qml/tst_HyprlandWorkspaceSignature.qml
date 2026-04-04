import QtQuick 2.15
import QtTest 1.2
import "../../Services/Compositor/HyprlandWorkspaceSignature.js" as HyprlandWorkspaceSignature

TestCase {
  name: "HyprlandWorkspaceSignature"

  function test_signature_changes_when_scratchpad_exists_only_in_toplevels() {
    const workspaces = [
      { id: 1, active: true, focused: true, name: "1" }
    ];
    const occupiedIds = { 1: true };

    const withoutScratchpad = [];
    const withScratchpad = [
      { workspace: { id: -97, name: "special:scratch" } }
    ];

    const baseSignature = HyprlandWorkspaceSignature.buildSignature(workspaces, occupiedIds, withoutScratchpad);
    const scratchpadSignature = HyprlandWorkspaceSignature.buildSignature(workspaces, occupiedIds, withScratchpad);

    compare(baseSignature === scratchpadSignature, false);
  }
}
