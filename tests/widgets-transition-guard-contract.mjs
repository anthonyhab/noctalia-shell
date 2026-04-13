import fs from "node:fs";
import path from "node:path";

const widgetsRoot = path.resolve("Widgets");

function listQmlFiles(dir) {
  const entries = fs.readdirSync(dir, {
    withFileTypes: true,
  });
  const files = [];
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...listQmlFiles(fullPath));
      continue;
    }
    if (entry.isFile() && fullPath.endsWith(".qml")) {
      files.push(fullPath);
    }
  }
  return files;
}

function lineAtOffset(text, offset) {
  return text.slice(0, offset).split("\n").length;
}

function findBehaviorBlocks(text) {
  const blocks = [];
  const behaviorRe = /Behavior\s+on\s+(color|border\.color)\s*\{/g;
  let match = behaviorRe.exec(text);

  while (match) {
    const prop = match[1];
    const blockStart = match.index;
    let cursor = blockStart;
    let depth = 0;
    let opened = false;

    while (cursor < text.length) {
      const ch = text[cursor];
      if (ch === "{") {
        depth += 1;
        opened = true;
      } else if (ch === "}") {
        depth -= 1;
        if (opened && depth === 0) {
          cursor += 1;
          break;
        }
      }
      cursor += 1;
    }

    blocks.push({
      prop,
      start: blockStart,
      body: text.slice(blockStart, cursor),
    });

    match = behaviorRe.exec(text);
  }

  return blocks;
}

const files = listQmlFiles(widgetsRoot);
const violations = [];

for (const file of files) {
  const text = fs.readFileSync(file, "utf8");
  const blocks = findBehaviorBlocks(text);
  for (const block of blocks) {
    if (!block.body.includes("enabled:") || !block.body.includes("!Color.isTransitioning")) {
      violations.push({
        file: path.relative(path.resolve("."), file),
        line: lineAtOffset(text, block.start),
        prop: block.prop,
      });
    }
  }
}

if (violations.length > 0) {
  console.error("Expected all widget color behaviors to guard against global theme transitions.");
  for (const violation of violations) {
    console.error(`- ${violation.file}:${violation.line} Behavior on ${violation.prop} missing \"enabled: !Color.isTransitioning\"`);
  }
  process.exit(1);
}
