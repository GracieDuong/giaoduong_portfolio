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
const ACCENT = "#ff7a00";
const ACCENT_LIGHT = "rgba(255,122,0,0.72)";
const ACCENT_SOFT = "rgba(255,122,0,0.18)";

const DANGER = "#ef4444";
const DANGER_LIGHT = "rgba(239,68,68,0.72)";
const DANGER_SOFT = "rgba(239,68,68,0.18)";

const SUCCESS = "#22c55e";
const SUCCESS_LIGHT = "rgba(34,197,94,0.72)";
const SUCCESS_SOFT = "rgba(34,197,94,0.18)";

const WARNING = "#f59e0b";
const WARNING_LIGHT = "rgba(245,158,11,0.72)";
const WARNING_SOFT = "rgba(245,158,11,0.18)";

const BLUE = "#38bdf8";
const BLUE_SOFT = "rgba(56,189,248,0.18)";

const MUTED = "#9ca3af";
const TEXT = "#ffffff";
const GRID = "rgba(255,255,255,0.08)";
/* Growth */
mkChart("c-growth","bar",D.monthly.labels,[
  {
    label:"Applications",
    data:D.monthly.apps,
    backgroundColor:ACCENT_SOFT,
    borderColor:ACCENT,
    borderWidth:1.5,
    borderRadius:6,
    yAxisID:"y"
  },
  {
    label:"Funded Amount",
    data:D.monthly.funded,
    type:"line",
    borderColor:BLUE,
    backgroundColor:BLUE_SOFT,
    fill:true,
    tension:.35,
    pointRadius:4,
    pointBackgroundColor:BLUE,
    pointBorderColor:"#101010",
    pointBorderWidth:2,
    yAxisID:"y2"
  }
],{
  scales:{
    x:{ticks:{color:MUTED},grid:{display:false}},
    y:{ticks:{color:MUTED,callback:v=>v>=1000?v/1000+"K":v},grid:{color:GRID}},
    y2:{position:"right",ticks:{color:BLUE,callback:v=>"$"+v+"M"},grid:{display:false}}
  }
});
