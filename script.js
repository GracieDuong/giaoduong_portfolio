const header = document.querySelector(".site-header");
const menu = document.getElementById("menu");
const menuToggle = document.getElementById("menuToggle");
const toTop = document.getElementById("toTop");
const revealItems = document.querySelectorAll(".reveal");
const navLinks = document.querySelectorAll(".menu a");
const sections = document.querySelectorAll("section[id]");

menuToggle.addEventListener("click", () => {
  menu.classList.toggle("open");
});

navLinks.forEach((link) => {
  link.addEventListener("click", () => {
    menu.classList.remove("open");
  });
});

window.addEventListener("scroll", () => {
  header.classList.toggle("scrolled", window.scrollY > 12);
  toTop.classList.toggle("show", window.scrollY > 320);
  updateActiveLink();
});

toTop.addEventListener("click", () => {
  window.scrollTo({
    top: 0,
    behavior: "smooth"
  });
});

function updateActiveLink() {
  let current = "";

  sections.forEach((section) => {
    const top = section.offsetTop - 140;
    const height = section.offsetHeight;

    if (window.scrollY >= top && window.scrollY < top + height) {
      current = section.getAttribute("id");
    }
  });

  navLinks.forEach((link) => {
    link.classList.remove("active");
    if (link.getAttribute("href") === `#${current}`) {
      link.classList.add("active");
    }
  });
}

const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add("visible");
      }
    });
  },
  {
    threshold: 0.12
  }
);

revealItems.forEach((item) => observer.observe(item));

document.addEventListener("click", (e) => {
  const isClickMenu = menu.contains(e.target);
  const isClickToggle = menuToggle.contains(e.target);

  if (!isClickMenu && !isClickToggle) {
    menu.classList.remove("open");
  }
});
