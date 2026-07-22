(() => {
  const demo = document.querySelector(".demo-window");
  if (!demo || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

  const title = demo.querySelector("[data-demo-title]");
  const hint = demo.querySelector("[data-demo-hint]");
  const status = demo.querySelector("[data-demo-status]");
  const transcript = demo.querySelector("[data-demo-transcript]");
  const transcripts = [
    "Remember to send the final draft before lunch.",
    "Move the product review to Thursday afternoon.",
    "The opening should feel direct, useful, and human."
  ];
  let transcriptIndex = 0;
  let timer;

  const setState = (state) => {
    demo.dataset.state = state;

    if (state === "listening") {
      transcriptIndex = (transcriptIndex + 1) % transcripts.length;
      title.textContent = "Listening";
      hint.textContent = "to finish";
      status.textContent = "Live";
      transcript.textContent = transcripts[transcriptIndex];
      timer = window.setTimeout(() => setState("transcribing"), 4200);
      return;
    }

    if (state === "transcribing") {
      title.textContent = "Transcribing";
      hint.textContent = "processing locally";
      status.textContent = "Working";
      timer = window.setTimeout(() => setState("copied"), 1500);
      return;
    }

    title.textContent = "Copied";
    hint.textContent = "ready to paste";
    status.textContent = "Copied";
    timer = window.setTimeout(() => setState("listening"), 2200);
  };

  timer = window.setTimeout(() => setState("transcribing"), 4200);
  document.addEventListener("visibilitychange", () => {
    if (document.hidden) {
      window.clearTimeout(timer);
    } else {
      setState("listening");
    }
  });
})();
