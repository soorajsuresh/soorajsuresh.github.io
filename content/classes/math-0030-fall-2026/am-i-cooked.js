const score1 = document.getElementById("score1");
const total1 = document.getElementById("total1");
const score2 = document.getElementById("score2");
const total2 = document.getElementById("total2");

const result = document.getElementById("result");
const button = document.getElementById("calculate");

button.addEventListener("click", () => {
    /*const p1 = s1 / t1 * 100;
    const p2 = s2 / t2 * 100;*/
    const s1 = Number(score1.value);
    const t1 = Number(total1.value);
    const s2 = Number(score2.value);
    const t2 = Number(total2.value);
    const p1 = Number(percent1.value) / 100;
    const p2 = Number(percent2.value) / 100;
    const cooked_threshold = (1.8 - p1 - p2) * 100;

    result.textContent =
        "To earn an average grade above an F for Exams 1-3, you must earn ";

    const number_container = document.createElement("div");
    number_container.id = "cooked-threshold";

    result.append(number_container);

    const duration = 2000;
    const start = performance.now();

    function animate(now) {
        const progress = Math.min((now - start) / duration, 1);
        const ease = 1 - Math.pow(1.5, -10 * progress);
        const value = cooked_threshold * ease;

        number_container.textContent = `${value.toFixed(2)}%`;

        if (progress < 1) {
            requestAnimationFrame(animate);
        } else {
            const description = document.createElement("div");
            description.id = "description";
            if (cooked_threshold > 100) {
                wave_text(description, "You are burnt to a crisp.");
            } else if (cooked_threshold === 100) {
                wave_text(description, "You are cooked to perfection.");
            } else if (cooked_threshold >= 90) {
                wave_text(description, "You are cooked.");
            } else if (cooked_threshold >= 80) {
                wave_text(description, "You are medium.");
            } else if (cooked_threshold >= 70) {
                wave_text(description, "You are medium-rare.");
            } else if (cooked_threshold >= 60) {
                wave_text(description, "You are rare.");
            } else if (cooked_threshold >= 50) {
                wave_text(description, "You are raw.");
            } else if (cooked_threshold === -10.58) {
                wave_text(description, "You are Albert.");
            }

            result.append(description);

            requestAnimationFrame(() => {
                description.classList.add("visible");
            });
        }
    }
    requestAnimationFrame(animate);
});

function wave_text(element, text) {
    element.replaceChildren();

    [...text].forEach((char, i) => {
        const span = document.createElement("span");
        span.textContent = char === " " ? "\u00A0" : char;
        span.style.setProperty("--i", i);
        element.append(span);
    });
}