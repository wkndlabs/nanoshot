import Image from "next/image";
import Link from "next/link";
import {
  AppWindow,
  Crop,
  Download,
  Eye,
  Keyboard,
  Layers,
  Menu,
  Monitor,
  RefreshCw,
} from "lucide-react";
import { Button } from "@/components/ui/button";

function GithubIcon({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden
      className={className}
    >
      <path d="M12 .5C5.65.5.5 5.65.5 12c0 5.08 3.29 9.39 7.86 10.91.58.1.79-.25.79-.56v-2.18c-3.2.7-3.87-1.37-3.87-1.37-.52-1.32-1.27-1.67-1.27-1.67-1.04-.71.08-.7.08-.7 1.15.08 1.76 1.18 1.76 1.18 1.02 1.75 2.69 1.25 3.35.96.1-.74.4-1.25.72-1.54-2.55-.29-5.24-1.27-5.24-5.65 0-1.25.45-2.27 1.18-3.07-.12-.29-.51-1.46.11-3.04 0 0 .96-.31 3.16 1.17.92-.26 1.9-.39 2.88-.39.98 0 1.96.13 2.88.39 2.2-1.48 3.16-1.17 3.16-1.17.62 1.58.23 2.75.11 3.04.74.8 1.18 1.82 1.18 3.07 0 4.39-2.69 5.36-5.25 5.64.41.35.78 1.04.78 2.1v3.11c0 .31.21.66.8.55 4.56-1.52 7.85-5.83 7.85-10.91C23.5 5.65 18.35.5 12 .5Z" />
    </svg>
  );
}

const features = [
  {
    icon: Crop,
    title: "Region capture",
    body: "Drag to select any rectangle on screen. Pixel-precise.",
  },
  {
    icon: Monitor,
    title: "Full screen",
    body: "Snap the active display in a single keystroke.",
  },
  {
    icon: AppWindow,
    title: "Window capture",
    body: "Click any window to capture just that window — no cropping.",
  },
  {
    icon: Keyboard,
    title: "Custom hotkeys",
    body: "Rebind anything. Nanoshot warns you about conflicts during onboarding.",
  },
  {
    icon: Eye,
    title: "Quick preview",
    body: "A thumbnail appears after each capture with Save and Delete actions.",
  },
  {
    icon: Layers,
    title: "Desktop cover",
    body: "Optionally hide desktop icons and wallpaper clutter while you shoot.",
  },
  {
    icon: Menu,
    title: "Menubar-first",
    body: "Lives in the menu bar. The Dock icon is optional.",
  },
  {
    icon: RefreshCw,
    title: "Auto-update",
    body: "Direct-download builds pull the latest release from GitHub and swap in place.",
  },
];

export default function Home() {
  return (
    <>
      <header className="sticky top-0 z-40 w-full border-b border-border/50 bg-background/80 backdrop-blur-md">
        <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-6">
          <Link href="/" className="flex items-center gap-2">
            <Image
              src="/icon.png"
              alt=""
              width={24}
              height={24}
              className="rounded"
            />
            <span className="text-sm font-semibold tracking-tight">
              Nanoshot
            </span>
          </Link>
          <nav className="flex items-center gap-1 text-sm">
            <Button variant="ghost" size="sm" asChild>
              <Link href="/docs">Docs</Link>
            </Button>
            <Button variant="ghost" size="sm" asChild>
              <a
                href="https://github.com/wkndlabs/nanoshot"
                target="_blank"
                rel="noopener noreferrer"
              >
                <GithubIcon className="size-4" />
                GitHub
              </a>
            </Button>
          </nav>
        </div>
      </header>

      <main className="flex flex-1 flex-col">
        <section className="relative overflow-hidden">
          <div
            className="pointer-events-none absolute inset-0 -z-10"
            aria-hidden
            style={{
              background:
                "radial-gradient(ellipse 60% 50% at 50% -10%, rgba(0,136,255,0.18), transparent 70%)",
            }}
          />
          <div className="mx-auto flex max-w-3xl flex-col items-center px-6 pt-24 pb-20 text-center sm:pt-32 sm:pb-28">
            <Image
              src="/icon.png"
              alt="Nanoshot"
              width={128}
              height={128}
              priority
              className="mb-10 rounded-3xl shadow-2xl shadow-primary/20"
            />
            <h1 className="text-balance text-5xl font-semibold leading-[1.05] tracking-tight sm:text-6xl">
              A tiny menubar screenshot tool for macOS.
            </h1>
            <p className="mt-6 max-w-xl text-balance text-lg leading-relaxed text-muted-foreground">
              Region, screen, and window captures with your own global
              shortcuts, a quick-action preview, and optional desktop cleanup
              while you shoot.
            </p>
            <div className="mt-10 flex flex-col gap-3 sm:flex-row">
              <Button size="lg" asChild>
                <a href="#install">
                  <Download />
                  Download
                </a>
              </Button>
              <Button size="lg" variant="outline" asChild>
                <a
                  href="https://github.com/wkndlabs/nanoshot"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <GithubIcon className="size-4" />
                  View on GitHub
                </a>
              </Button>
            </div>
            <p className="mt-6 text-xs text-muted-foreground">
              Free and open source · macOS 26.4+
            </p>
          </div>
        </section>

        <section className="border-t border-border/50">
          <div className="mx-auto max-w-6xl px-6 py-24">
            <div className="mx-auto max-w-2xl text-center">
              <h2 className="text-balance text-3xl font-semibold tracking-tight sm:text-4xl">
                Everything you need. Nothing you don&apos;t.
              </h2>
              <p className="mt-4 text-muted-foreground">
                Built for people who hit ⌘⇧4 a hundred times a day.
              </p>
            </div>
            <div className="mt-16 grid grid-cols-1 gap-px overflow-hidden rounded-2xl border border-border/60 bg-border/60 sm:grid-cols-2 lg:grid-cols-4">
              {features.map(({ icon: Icon, title, body }) => (
                <div
                  key={title}
                  className="flex flex-col gap-3 bg-card p-6 transition-colors hover:bg-card/60"
                >
                  <Icon className="size-5 text-primary" />
                  <h3 className="text-base font-semibold">{title}</h3>
                  <p className="text-sm leading-relaxed text-muted-foreground">
                    {body}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section id="install" className="border-t border-border/50">
          <div className="mx-auto max-w-3xl px-6 py-24">
            <div className="text-center">
              <h2 className="text-balance text-3xl font-semibold tracking-tight sm:text-4xl">
                Install
              </h2>
              <p className="mt-4 text-muted-foreground">
                Three channels. Pick whichever fits.
              </p>
            </div>
            <div className="mt-12 grid gap-4">
              <InstallCard
                title="Mac App Store"
                description="One-click install, auto-updates handled by macOS. Sandboxed build."
                cta="Open in App Store"
                href="https://apps.apple.com/app/nanoshot/id0000000000"
              />
              <InstallCard
                title="Homebrew"
                description="For terminal-first folks. Tracks the latest GitHub Release."
                cta={null}
                code="brew install --cask nanoshot"
              />
              <InstallCard
                title="Direct download"
                description="Signed and notarized .zip from GitHub Releases. Auto-updates in place."
                cta="Latest release"
                href="https://github.com/wkndlabs/nanoshot/releases"
              />
            </div>
          </div>
        </section>
      </main>

      <footer className="border-t border-border/50">
        <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 px-6 py-10 text-sm text-muted-foreground sm:flex-row">
          <div className="flex items-center gap-2">
            <Image
              src="/icon.png"
              alt=""
              width={20}
              height={20}
              className="rounded"
            />
            <span>Nanoshot</span>
            <span aria-hidden>·</span>
            <span>MIT licensed</span>
          </div>
          <div className="flex items-center gap-5">
            <Link href="/docs" className="hover:text-foreground">
              Docs
            </Link>
            <a
              href="https://github.com/wkndlabs/nanoshot"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-foreground"
            >
              GitHub
            </a>
            <a
              href="https://github.com/wkndlabs/nanoshot/issues"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-foreground"
            >
              Issues
            </a>
          </div>
        </div>
      </footer>
    </>
  );
}

type InstallCardProps = {
  title: string;
  description: string;
  cta: string | null;
  href?: string;
  code?: string;
};

function InstallCard({
  title,
  description,
  cta,
  href,
  code,
}: InstallCardProps) {
  return (
    <div className="rounded-xl border border-border/60 bg-card p-6 transition-colors hover:border-border">
      <div className="flex flex-col items-start justify-between gap-4 sm:flex-row sm:items-center">
        <div className="flex-1">
          <h3 className="text-lg font-semibold">{title}</h3>
          <p className="mt-1 text-sm text-muted-foreground">{description}</p>
        </div>
        {cta && href ? (
          <Button variant="outline" asChild>
            <a href={href} target="_blank" rel="noopener noreferrer">
              {cta}
            </a>
          </Button>
        ) : null}
      </div>
      {code ? (
        <pre className="mt-4 overflow-x-auto rounded-md border border-border/60 bg-background px-4 py-3 font-mono text-sm">
          <code>{code}</code>
        </pre>
      ) : null}
    </div>
  );
}
