(() => {
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const revealItems = document.querySelectorAll(".reveal");

  if (reducedMotion || !("IntersectionObserver" in window)) {
    revealItems.forEach((item) => item.classList.add("is-visible"));
  } else {
    const observer = new IntersectionObserver((entries, revealObserver) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-visible");
        revealObserver.unobserve(entry.target);
      });
    }, { threshold: 0.11, rootMargin: "0px 0px -6% 0px" });

    revealItems.forEach((item) => observer.observe(item));
  }

  if (!reducedMotion && window.matchMedia("(pointer: fine)").matches) {
    const hero = document.querySelector(".hero");
    const art = document.querySelector(".hero-art");
    if (hero && art) {
      hero.addEventListener("pointermove", (event) => {
        const bounds = hero.getBoundingClientRect();
        const x = (event.clientX - bounds.left) / bounds.width - 0.5;
        const y = (event.clientY - bounds.top) / bounds.height - 0.5;
        art.style.transform = `scale(1.025) translate(${x * -7}px, ${y * -5}px)`;
      });
      hero.addEventListener("pointerleave", () => {
        art.style.transform = "scale(1.012)";
      });
    }
  }
})();
