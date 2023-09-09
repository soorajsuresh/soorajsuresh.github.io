const steps = document.querySelector('steps');
let isDown = false;
let startX;
let scrollLeft;
let completion = 0;
const thresh = 120;
const width = 600;

const example_progress_bar = document.createElement("div");
example_progress_bar.class = "example_progress_bar";
example_progress_bar.style.position = 'absolute';
example_progress_bar.style.top = 'auto';
example_progress_bar.style.bottom = 0;
example_progress_bar.style.left = '0px';
example_progress_bar.style.backgroundColor = 'rgb(var(--bloo))';
example_progress_bar.style.height = '2px';
example_progress_bar.style.width = width / steps.scrollWidth * 100 + '%';
steps.parentNode.appendChild(example_progress_bar);

const drag_bar = document.createElement("div");
drag_bar.class = "drag_bar";
drag_bar.style.position = 'absolute';
drag_bar.style.top = '0px';
drag_bar.style.left = '0px';
drag_bar.style.backgroundColor = 'rgb(var(--bloo))';
drag_bar.style.height = '2px';
drag_bar.style.minWidth = 0;
steps.parentNode.appendChild(drag_bar);

steps.addEventListener('scrollend', (e) => {
    example_progress_bar.style.width = ((steps.scrollLeft + width) / steps.scrollWidth) * 100 + '%';
    console.log("we scrollin");
});

steps.addEventListener('mousedown', (e) => {
    e.preventDefault();
    if (e.button == 0) {
        isDown = true;
        startX = e.pageX - steps.offsetLeft;
        scrollLeft = steps.scrollLeft;
    }
});

steps.addEventListener('mouseup', (e) => {    
    if (!isDown) return;
    e.preventDefault();
    drag_bar.style.width = 0;
    if (completion > thresh) {
        steps.scrollBy({
            left: width,
            top: 0,
            behavior: 'smooth'
        });
    } else if (completion < -thresh) {
        steps.scrollBy({
            left: -width,
            top: 0,
            behavior: 'smooth'
        });
    }
    isDown = false;
});

steps.addEventListener('mouseleave', (e) => {
    if (!isDown) return;
    e.preventDefault();
    isDown = false;
    drag_bar.style.width = 0;
});

steps.addEventListener('mousemove', (e) => {
    if (!isDown) return;
    e.preventDefault();
    const x = e.pageX - steps.offsetLeft;
    const walk = (x - startX) * 2;
    completion = -walk;
    if (completion > 0) {
        drag_bar.style.left = 0;
        drag_bar.style.right = 'auto';
        drag_bar.style.width = Math.abs(completion / thresh) * 100 + "%";
    } else {
        drag_bar.style.right = 0;
        drag_bar.style.left = 'auto';
        drag_bar.style.width = Math.abs(completion / thresh) * 100 + "%";
    }
});
