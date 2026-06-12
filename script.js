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
/* Donut */
new Chart(document.getElementById("c-goodbad-donut"),{
  type:"doughnut",
  data:{
    labels:["Good Loan","Bad Loan"],
    datasets:[{
      data:[86.18,13.82],
      backgroundColor:[SUCCESS, DANGER],
      hoverBackgroundColor:[SUCCESS_LIGHT, DANGER_LIGHT],
      borderColor:"#101010",
      borderWidth:4,
      hoverOffset:8
    }]
  },
  options:{
    responsive:true,
    maintainAspectRatio:false,
    cutout:"68%",
    plugins:{
      legend:{
        display:true,
        position:"bottom",
        labels:{
          color:MUTED,
          boxWidth:10,
          boxHeight:10,
          usePointStyle:true,
          pointStyle:"circle"
        }
      }
    }
  }
});
/* Good bad bar */
mkChart("c-goodbad-bar","bar",["Good Loan","Bad Loan"],[
  {
    label:"Funded",
    data:[370.22,65.53],
    backgroundColor:[SUCCESS_SOFT,DANGER_SOFT],
    borderColor:[SUCCESS,DANGER],
    borderWidth:1.5,
    borderRadius:6
  },
  {
    label:"Received",
    data:[435.79,37.28],
    backgroundColor:[SUCCESS_LIGHT,DANGER_LIGHT],
    borderColor:[SUCCESS,DANGER],
    borderWidth:1,
    borderRadius:6
  }
],{
  scales:{
    x:{ticks:{color:MUTED},grid:{display:false}},
    y:{ticks:{color:MUTED,callback:v=>"$"+v+"M"},grid:{color:GRID}}
  }
});
const gradeColors = [
  SUCCESS_LIGHT,
  "rgba(132,204,22,0.78)",
  WARNING_LIGHT,
  "rgba(249,115,22,0.78)",
  DANGER_LIGHT,
  "rgba(220,38,38,0.82)",
  "rgba(153,27,27,0.88)"
];
{
  data:D.dti.bad_rate,
  backgroundColor:[SUCCESS_LIGHT, WARNING_LIGHT, DANGER_LIGHT],
  borderColor:[SUCCESS, WARNING, DANGER],
  borderWidth:1.5,
  borderRadius:5
}
datasets:[{
  data:D.purpose_risk.bad_rate,
  backgroundColor:D.purpose_risk.bad_rate.map(v =>
    v > 20 ? DANGER_LIGHT : v > 14 ? WARNING_LIGHT : SUCCESS_LIGHT
  ),
  borderColor:D.purpose_risk.bad_rate.map(v =>
    v > 20 ? DANGER : v > 14 ? WARNING : SUCCESS
  ),
  borderWidth:1,
  borderRadius:4
}]
datasets:[
  {
    label:"MoM Change",
    data:D.monthly.mom,
    backgroundColor:D.monthly.mom.map(v => v > 0 ? DANGER_SOFT : SUCCESS_SOFT),
    borderColor:D.monthly.mom.map(v => v > 0 ? DANGER : SUCCESS),
    borderWidth:1.5,
    borderRadius:5,
    yAxisID:"y2"
  },
  {
    label:"Bad Loan Rate",
    data:D.monthly.bad_rate,
    type:"line",
    borderColor:DANGER,
    backgroundColor:DANGER_SOFT,
    fill:true,
    tension:.35,
    pointRadius:4,
    pointBackgroundColor:DANGER,
    pointBorderColor:"#101010",
    pointBorderWidth:2,
    yAxisID:"y"
  }
]
/* Monthly table */
const monthlyBody = document.getElementById("monthly-detail-body");

const riskBadge = rate => {
  if (rate >= 15) return `<span class="risk-flag high">${rate.toFixed(2)}%</span>`;
  if (rate >= 13.5) return `<span class="risk-flag medium">${rate.toFixed(2)}%</span>`;
  return `<span class="risk-flag low">${rate.toFixed(2)}%</span>`;
};

const momBadge = mom => {
  if (mom === 0) return `<span class="risk-flag neutral">—</span>`;
  if (mom > 1) return `<span class="risk-flag high">+${mom.toFixed(2)}pp</span>`;
  if (mom > 0) return `<span class="risk-flag medium">+${mom.toFixed(2)}pp</span>`;
  return `<span class="risk-flag low">${mom.toFixed(2)}pp</span>`;
};

D.monthly.labels.forEach((m,i) => {
  const mom = D.monthly.mom[i];
  const badLoans = Math.round(D.monthly.apps[i] * D.monthly.bad_rate[i] / 100);

  monthlyBody.innerHTML += `
    <tr>
      <td>${m}</td>
      <td>${D.monthly.apps[i].toLocaleString()}</td>
      <td>${badLoans.toLocaleString()}</td>
      <td>${riskBadge(D.monthly.bad_rate[i])}</td>
      <td>${momBadge(mom)}</td>
      <td>$${D.monthly.funded[i].toFixed(1)}M</td>
    </tr>
  `;
});
