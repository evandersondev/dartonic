import { Footer } from "@/components/Footer";
import { Navbar } from "@/components/Navbar";
import { Comparison } from "@/components/sections/Comparison";
import { CTA } from "@/components/sections/CTA";
import { Examples } from "@/components/sections/Examples";
import { Features } from "@/components/sections/Features";
import { Hero } from "@/components/sections/Hero";
import { HowItWorks } from "@/components/sections/HowItWorks";
import { Performance } from "@/components/sections/Performance";
import { RealWorld } from "@/components/sections/RealWorld";
import { UsedFor } from "@/components/sections/UsedFor";
import { Why } from "@/components/sections/Why";
import { createFileRoute } from "@tanstack/react-router";
import { useEffect } from "react";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Dartonic — Type-safe SQL for Dart" },
      {
        name: "description",
        content:
          "Dartonic is a type-safe SQL query builder and ORM for Dart, inspired by Drizzle. No code generation, no dynamic — one schema for SQLite, PostgreSQL and MySQL.",
      },
    ],
  }),
  component: IndexPage,
});

function IndexPage() {
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("in-view");
          }
        });
      },
      { threshold: 0.1, rootMargin: "0px 0px -40px 0px" },
    );

    const sections = document.querySelectorAll(".section-animate");
    sections.forEach((el) => observer.observe(el));

    return () => observer.disconnect();
  }, []);

  return (
    <>
      <Navbar />
      <main>
        <Hero />
        <HowItWorks />
        <Why />
        <Features />
        <UsedFor />
        <Examples />
        <RealWorld />
        <Performance />
        <Comparison />
        <CTA />
      </main>
      <Footer />
    </>
  );
}
