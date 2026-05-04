import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { getAllDocs } from "@/lib/docs";

export const metadata = {
  title: "Docs — Nanoshot",
};

export default async function DocsIndex() {
  const docs = await getAllDocs();

  return (
    <main className="mx-auto max-w-3xl px-6 py-24">
      <Link
        href="/"
        className="mb-10 inline-block text-sm text-muted-foreground hover:text-foreground"
      >
        ← Home
      </Link>
      <h1 className="mb-3 text-4xl font-semibold tracking-tight">Docs</h1>
      <p className="mb-12 text-muted-foreground">
        Everything you need to use Nanoshot.
      </p>
      <ul className="divide-y divide-border/60 rounded-xl border border-border/60 bg-card">
        {docs.map((doc) => (
          <li key={doc.slug}>
            <Link
              href={`/docs/${doc.slug}`}
              className="flex items-center justify-between px-6 py-5 transition-colors hover:bg-muted/40"
            >
              <span className="text-base font-medium">{doc.title}</span>
              <ArrowRight className="size-4 text-muted-foreground" />
            </Link>
          </li>
        ))}
      </ul>
    </main>
  );
}
