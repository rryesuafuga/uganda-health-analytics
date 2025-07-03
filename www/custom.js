// www/custom.js - Uganda Health Analytics Dashboard
// Performance optimized JavaScript with debouncing and lazy loading

// Namespace for our app
const UgandaHealthApp = {
  config: {
    debounceDelay: 300,
    animationDuration: 2000,
    lazyLoadOffset: 50,
    particleCount: 100
  },
  
  state: {
    isLoading: false,
    currentTab: 'dashboard',
    cachedData: new Map()
  }
};

// Utility Functions
const Utils = {
  // Debounce function for performance
  debounce: function(func, wait) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  },
  
  // Throttle function for scroll events
  throttle: function(func, limit) {
    let inThrottle;
    return function(...args) {
      if (!inThrottle) {
        func.apply(this, args);
        inThrottle = true;
        setTimeout(() => inThrottle = false, limit);
      }
    };
  },
  
  // Format numbers with commas
  formatNumber: function(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  },
  
  // Animate value changes
  animateValue: function(element, start, end, duration = 2000) {
    if (!element) return;
    
    const range = end - start;
    const startTime = performance.now();
    
    const update = (currentTime) => {
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);
      
      // Easing function
      const easeOutQuart = 1 - Math.pow(1 - progress, 4);
      const current = start + (range * easeOutQuart);
      
      element.textContent = Utils.formatNumber(Math.round(current));
      
      if (progress < 1) {
        requestAnimationFrame(update);
      }
    };
    
    requestAnimationFrame(update);
  }
};

// Particle System for background animation
class ParticleSystem {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.particles = [];
    this.animationId = null;
    
    this.resize();
    this.init();
    
    // Bind event listeners
    window.addEventListener('resize', Utils.debounce(() => this.resize(), 250));
    document.addEventListener('visibilitychange', () => this.handleVisibilityChange());
  }
  
  resize() {
    this.canvas.width = window.innerWidth;
    this.canvas.height = window.innerHeight;
  }
  
  init() {
    const count = window.innerWidth < 768 ? 50 : UgandaHealthApp.config.particleCount;
    
    for (let i = 0; i < count; i++) {
      this.particles.push({
        x: Math.random() * this.canvas.width,
        y: Math.random() * this.canvas.height,
        vx: (Math.random() - 0.5) * 0.5,
        vy: (Math.random() - 0.5) * 0.5,
        radius: Math.random() * 2 + 0.5,
        opacity: Math.random() * 0.5 + 0.1
      });
    }
    
    this.animate();
  }
  
  animate() {
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    
    // Update and draw particles
    this.particles.forEach((particle, i) => {
      // Update position
      particle.x += particle.vx;
      particle.y += particle.vy;
      
      // Wrap around edges
      if (particle.x < 0) particle.x = this.canvas.width;
      if (particle.x > this.canvas.width) particle.x = 0;
      if (particle.y < 0) particle.y = this.canvas.height;
      if (particle.y > this.canvas.height) particle.y = 0;
      
      // Draw particle
      this.ctx.beginPath();
      this.ctx.arc(particle.x, particle.y, particle.radius, 0, Math.PI * 2);
      this.ctx.fillStyle = `rgba(255, 98, 0, ${particle.opacity})`;
      this.ctx.fill();
      
      // Draw connections
      this.particles.slice(i + 1).forEach(other => {
        const dist = Math.hypot(other.x - particle.x, other.y - particle.y);
        if (dist < 100) {
          this.ctx.beginPath();
          this.ctx.moveTo(particle.x, particle.y);
          this.ctx.lineTo(other.x, other.y);
          this.ctx.strokeStyle = `rgba(255, 98, 0, ${0.1 * (1 - dist / 100)})`;
          this.ctx.stroke();
        }
      });
    });
    
    this.animationId = requestAnimationFrame(() => this.animate());
  }
  
  handleVisibilityChange() {
    if (document.hidden) {
      cancelAnimationFrame(this.animationId);
    } else {
      this.animate();
    }
  }
  
  destroy() {
    cancelAnimationFrame(this.animationId);
    window.removeEventListener('resize', this.resize);
    document.removeEventListener('visibilitychange', this.handleVisibilityChange);
  }
}

// Advanced D3.js Network Visualization
class NetworkVisualization {
  constructor(containerId, data) {
    this.container = d3.select(`#${containerId}`);
    this.data = data;
    this.simulation = null;
    
    this.init();
  }
  
  init() {
    const rect = this.container.node().getBoundingClientRect();
    const width = rect.width || 800;
    const height = 500;
    
    // Clear previous content
    this.container.selectAll('*').remove();
    
    // Create SVG
    const svg = this.container
      .append('svg')
      .attr('width', width)
      .attr('height', height)
      .attr('viewBox', [0, 0, width, height]);
    
    // Add gradient definitions
    const defs = svg.append('defs');
    
    const gradient = defs.append('linearGradient')
      .attr('id', 'nodeGradient')
      .attr('x1', '0%')
      .attr('y1', '0%')
      .attr('x2', '100%')
      .attr('y2', '100%');
    
    gradient.append('stop')
      .attr('offset', '0%')
      .style('stop-color', '#FF6200')
      .style('stop-opacity', 1);
    
    gradient.append('stop')
      .attr('offset', '100%')
      .style('stop-color', '#FF8C42')
      .style('stop-opacity', 1);
    
    // Create force simulation
    this.simulation = d3.forceSimulation(this.data.nodes)
      .force('link', d3.forceLink(this.data.links)
        .id(d => d.id)
        .distance(d => 100 + d.value * 10))
      .force('charge', d3.forceManyBody().strength(-500))
      .force('center', d3.forceCenter(width / 2, height / 2))
      .force('collision', d3.forceCollide().radius(d => d.size + 20));
    
    // Create container groups
    const g = svg.append('g');
    
    // Enable zoom and pan
    const zoom = d3.zoom()
      .scaleExtent([0.5, 5])
      .on('zoom', (event) => {
        g.attr('transform', event.transform);
      });
    
    svg.call(zoom);
    
    // Create links
    const link = g.append('g')
      .attr('class', 'links')
      .selectAll('line')
      .data(this.data.links)
      .enter().append('line')
      .style('stroke', '#999')
      .style('stroke-opacity', 0.6)
      .style('stroke-width', d => Math.sqrt(d.value) * 2);
    
    // Create nodes
    const node = g.append('g')
      .attr('class', 'nodes')
      .selectAll('g')
      .data(
