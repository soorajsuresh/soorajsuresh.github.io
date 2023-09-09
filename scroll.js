// horizontal scrolling
document.querySelector("steps").addEventListener('wheel', function (evt) {
    console.log("we in here");
    if (evt.deltaY > 0)
        this.scrollBy({
            left: 600,
            top: 0,
            behavior: 'smooth'
        });
    else 
    this.scrollBy({
        left: -600,
        top: 0,
        behavior: 'smooth'
    });
    evt.preventDefault();
});

document.querySelector('steps').addEventListener('click', function (evt) {
    console.log("we in here");
    this.scrollBy({
        left: 600,
        top: 0,
        behavior: 'smooth'
    });
    evt.preventDefault();
});

/*document.querySelectorAll('example').forEach(item => {
    item.addEventListener('click', function () {
        console.log("we in here");
        this.scrollBy({
            left: 100,
            top: 0,
            behavior: 'smooth'
        })
    });
});*/

// smooth scrolling
$(document).ready(function(){
    $("a").on('click', function(event) {
        if (this.hash !== "") {
        event.preventDefault();
        let hash = this.hash;
        $('html, body').animate({
            scrollTop: $(hash).offset().top
        }, 200, function(){
            window.location.hash = hash;
        });
        }
    });
});