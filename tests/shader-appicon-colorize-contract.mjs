import fs from "node:fs";

const shaderPath = new URL("../Shaders/frag/appicon_colorize.frag", import.meta.url);
const shader = fs.readFileSync(shaderPath, "utf8");

if (!shader.includes("vec4 params;")) {
  console.error("Expected appicon_colorize shader to pack scalar controls into vec4 params.");
  process.exit(1);
}

if (shader.includes("float colorizeMode;")) {
  console.error("Did not expect trailing float colorizeMode uniform in appicon_colorize shader.");
  process.exit(1);
}

const qmlFiles = [
  "../Modules/Dock/DockContent.qml",
  "../Modules/Panels/Tray/TrayDrawerPanel.qml",
  "../Modules/Bar/Widgets/Tray.qml",
  "../Modules/Bar/Widgets/Launcher.qml",
  "../Modules/Bar/Widgets/ControlCenter.qml",
  "../Modules/Bar/Widgets/ActiveWindow.qml",
  "../Modules/Bar/Widgets/Taskbar.qml"
];

for (const relativePath of qmlFiles) {
  const path = new URL(relativePath, import.meta.url);
  const qml = fs.readFileSync(path, "utf8");
  if (qml.includes("property real colorizeMode:")) {
    console.error(`Did not expect legacy colorizeMode property in ${path.pathname}.`);
    process.exit(1);
  }
  if (!qml.includes("property vector4d params:")) {
    console.error(`Expected packed params property in ${path.pathname}.`);
    process.exit(1);
  }
}
