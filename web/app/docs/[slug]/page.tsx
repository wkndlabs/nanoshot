import Link from "next/link";
import { notFound } from "next/navigation";
import { getDoc, getDocSlugs } from "@/lib/docs";

export async function generateStaticParams() {
  const slugs = await getDocSlugs();
  return slugs.map((slug) => ({ slug }));
}

export async function generateMetadata(props: PageProps<"/docs/[slug]">) {
  const { slug } = await props.params;
  try {
    const doc = await getDoc(slug);
    return { title: `${doc.title} — Nanoshot` };
  } catch {
    return { title: "Docs — Nanoshot" };
  }
}

export default async function DocPage(props: PageProps<"/docs/[slug]">) {
  const { slug } = await props.params;

  let doc;
  try {
    doc = await getDoc(slug);
  } catch {
    notFound();
  }

  return (
    <main className="mx-auto max-w-3xl px-6 py-24">
      <Link
        href="/docs"
        className="mb-10 inline-block text-sm text-muted-foreground hover:text-foreground"
      >
        ← All docs
      </Link>
      <article
        className="markdown"
        dangerouslySetInnerHTML={{ __html: doc.html }}
      />
    </main>
  );
}
