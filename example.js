const example = document.querySelector('.example');
slides = example.querySelector('slides');
let scroll = 0, scrolling = false;
const WIDTH = 600;

const scroll_bar = document.createElement("div");
scroll_bar.class = "drag_bar";
scroll_bar.style.position = 'absolute';
scroll_bar.style.top = 'auto';
scroll_bar.style.bottom = scroll_bar.style.left = 0;
scroll_bar.style.backgroundColor = 'rgb(var(--bloo))';
scroll_bar.style.height = '2px';
scroll_bar.style.minWidth = 0;
example.appendChild(scroll_bar);
const SCROLL_SPEED = 20;

slides.addEventListener('scrollend', (e) => {
    scrolling = false;
});

slides.addEventListener('wheel', function (e) {
    if (!scrolling) {

        // update progress
        if (e.deltaY > 0) {
            scroll += SCROLL_SPEED;
        }  else if (e.deltaY < 0) {
            scroll -= SCROLL_SPEED;
        }

        // scroll next
        // check if there is more first?
        if (scroll > 100) {
            this.scrollBy({
                left: 600,
                top: 0,
                behavior: 'smooth'
            });
            scrolling = true;
            scroll = 0;
        }

        // scroll previous
        if (scroll < 0) {
            this.scrollBy({
                left: -600,
                top: 0,
                behavior: 'smooth'
            });
            scrolling = true;
            scroll = 0;
        }

        // update progress bar
        scroll_bar.style.width = scroll + '%';
    }
    e.preventDefault();
});
