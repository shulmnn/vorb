(() => {
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const revealItems = document.querySelectorAll(".reveal");

  if (reducedMotion || !("IntersectionObserver" in window)) {
    revealItems.forEach((item) => item.classList.add("is-visible"));
  } else {
    const revealObserver = new IntersectionObserver((entries, observer) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    }, { threshold: 0.12, rootMargin: "0px 0px -7% 0px" });

    revealItems.forEach((item) => revealObserver.observe(item));
  }

  const flowSteps = Array.from(document.querySelectorAll(".flow-list li"));
  if (!reducedMotion && flowSteps.length && "IntersectionObserver" in window) {
    const stepObserver = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        flowSteps.forEach((step) => step.classList.toggle("is-active", step === entry.target));
      });
    }, { threshold: 0.72 });

    flowSteps.forEach((step) => stepObserver.observe(step));
  }

  if (!reducedMotion) {
    const hero = document.querySelector(".hero-panel");
    const art = document.querySelector(".hero-art");
    if (hero && art && window.matchMedia("(pointer: fine)").matches) {
      hero.addEventListener("pointermove", (event) => {
        const bounds = hero.getBoundingClientRect();
        const x = (event.clientX - bounds.left) / bounds.width - 0.5;
        const y = (event.clientY - bounds.top) / bounds.height - 0.5;
        art.style.transform = `scale(1.035) translate(${x * -6}px, ${y * -4}px)`;
      });
      hero.addEventListener("pointerleave", () => {
        art.style.transform = "scale(1.012)";
      });
    }
  }
})();
