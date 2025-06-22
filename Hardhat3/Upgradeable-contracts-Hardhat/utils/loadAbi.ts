import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

// Recrée __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export function loadAbi(relativePath: string): unknown[] {
  const artifactPath = resolve(__dirname, relativePath);
  const artifactJson = JSON.parse(
    readFileSync(artifactPath, { encoding: "utf8" })
  );
  return artifactJson.abi;
}
