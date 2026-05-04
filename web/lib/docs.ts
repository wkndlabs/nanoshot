import { promises as fs } from "node:fs";
import path from "node:path";
import { marked } from "marked";

const DOCS_DIR = path.join(process.cwd(), "..", "docs");

export type Doc = {
  slug: string;
  title: string;
  html: string;
};

export async function getDocSlugs(): Promise<string[]> {
  const files = await fs.readdir(DOCS_DIR);
  return files
    .filter((f) => f.endsWith(".md"))
    .map((f) => f.replace(/\.md$/, ""));
}

export async function getDoc(slug: string): Promise<Doc> {
  const raw = await fs.readFile(path.join(DOCS_DIR, `${slug}.md`), "utf8");
  const titleMatch = raw.match(/^#\s+(.+)$/m);
  const title = titleMatch?.[1] ?? slug;
  const html = await marked.parse(raw);
  return { slug, title, html };
}

export async function getAllDocs(): Promise<Doc[]> {
  const slugs = await getDocSlugs();
  const docs = await Promise.all(slugs.map(getDoc));
  return docs.sort((a, b) => a.title.localeCompare(b.title));
}
