  (function () {
    var root = document.querySelector(".page");
    document.documentElement.classList.add("js");
    var reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    /* nav shadow on scroll */
    var nav = document.getElementById("nav");
    var onScroll = function () { nav.classList.toggle("scrolled", window.scrollY > 12); };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });

    /* reveal on view */
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add("in"); io.unobserve(e.target); } });
    }, { threshold: 0.15 });
    document.querySelectorAll(".reveal").forEach(function (el) { io.observe(el); });

    /* card tilt */
    if (!reduce) {
      document.querySelectorAll(".tilt").forEach(function (card) {
        card.addEventListener("pointermove", function (ev) {
          var r = card.getBoundingClientRect();
          var px = (ev.clientX - r.left) / r.width - 0.5;
          var py = (ev.clientY - r.top) / r.height - 0.5;
          card.style.setProperty("--ry", (px * 16).toFixed(2) + "deg");
          card.style.setProperty("--rx", (-py * 18).toFixed(2) + "deg");
        });
        card.addEventListener("pointerleave", function () {
          card.style.setProperty("--ry", "0deg");
          card.style.setProperty("--rx", "0deg");
        });
      });
    }

    /* hero parallax on islands */
    var art = document.querySelector(".hero__art");
    if (art && !reduce && window.matchMedia("(pointer:fine)").matches) {
      window.addEventListener("pointermove", function (ev) {
        var cx = ev.clientX / window.innerWidth - 0.5;
        var cy = ev.clientY / window.innerHeight - 0.5;
        var isles = art.querySelectorAll(".island");
        isles.forEach(function (isle, i) {
          var depth = (i + 1) * 6;
          isle.style.marginLeft = (cx * depth).toFixed(1) + "px";
          isle.style.marginTop = (cy * depth).toFixed(1) + "px";
        });
      }, { passive: true });
    }

    /* waitlist -> compose email (honest: no backend yet) */
    var form = document.getElementById("signup");
    var note = document.getElementById("note");
    form.addEventListener("submit", function (e) {
      e.preventDefault();
      var email = document.getElementById("email").value.trim();
      var ok = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
      if (!ok) { note.textContent = "Enter a valid email and I'll take it from there."; return; }
      var subject = encodeURIComponent("eyeland.cards itch.io build");
      var body = encodeURIComponent("Send me the first eyeland.cards itch.io build link: " + email);
      note.textContent = "Opening your email to confirm. See you in the Eyeland.";
      window.location.href = "mailto:adamtpang@gmail.com?subject=" + subject + "&body=" + body;
    });

    /* starfield */
    var canvas = document.getElementById("sky");
    var ctx = canvas.getContext("2d");
    var stars = [], dust = [], w = 0, h = 0, dpr = Math.min(window.devicePixelRatio || 1, 2);
    function resize() {
      w = canvas.clientWidth; h = canvas.clientHeight;
      canvas.width = w * dpr; canvas.height = h * dpr;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      var count = Math.min(150, Math.floor(w * h / 9000));
      stars = [];
      for (var i = 0; i < count; i++) {
        stars.push({ x: Math.random() * w, y: Math.random() * h, r: Math.random() * 1.3 + 0.2, a: Math.random() * 0.5 + 0.2, tw: Math.random() * 0.02 + 0.004, ph: Math.random() * 6.28 });
      }
      dust = [];
      for (var j = 0; j < 22; j++) {
        dust.push({ x: Math.random() * w, y: Math.random() * h, r: Math.random() * 1.4 + 0.6, sp: Math.random() * 0.18 + 0.05, hue: Math.random() > 0.5 ? "53,227,208" : "255,183,101" });
      }
    }
    var t = 0;
    function frame() {
      ctx.clearRect(0, 0, w, h);
      for (var i = 0; i < stars.length; i++) {
        var s = stars[i];
        var a = reduce ? s.a : s.a + Math.sin(t * s.tw + s.ph) * 0.28;
        ctx.globalAlpha = Math.max(0.05, a);
        ctx.fillStyle = "#dfe7ff";
        ctx.beginPath(); ctx.arc(s.x, s.y, s.r, 0, 6.2832); ctx.fill();
      }
      for (var k = 0; k < dust.length; k++) {
        var d = dust[k];
        ctx.globalAlpha = 0.5;
        ctx.fillStyle = "rgba(" + d.hue + ",0.7)";
        ctx.beginPath(); ctx.arc(d.x, d.y, d.r, 0, 6.2832); ctx.fill();
        if (!reduce) { d.y -= d.sp; d.x += Math.sin(d.y * 0.01) * 0.12; if (d.y < -4) { d.y = h + 4; d.x = Math.random() * w; } }
      }
      ctx.globalAlpha = 1;
      t += 1;
      if (!reduce) requestAnimationFrame(frame);
    }
    resize();
    frame();
    window.addEventListener("resize", function () { resize(); if (reduce) frame(); });
  })();
