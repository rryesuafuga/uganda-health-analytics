// Use debouncing for search inputs
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

// Optimize Shiny input updates
$(document).on('shiny:connected', function() {
  // Debounce search inputs
  $('.search-input').on('input', debounce(function() {
    Shiny.setInputValue('search', this.value);
  }, 300));
});

// Lazy load heavy components
const lazyLoadComponents = () => {
  const options = {
    root: null,
    rootMargin: '0px',
    threshold: 0.1
  };
  
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        // Load component
        Shiny.setInputValue('load_component', entry.target.id);
        observer.unobserve(entry.target);
      }
    });
  }, options);
  
  document.querySelectorAll('.lazy-load').forEach(el => {
    observer.observe(el);
  });
};
