/* ==========================================================================
   THE STYLEZONE - CORE JAVASCRIPT, THEME ENGINE & CSRF UTILITIES
   ========================================================================== */

// Helper to get CSRF token from meta tag or cookie
function getCsrfToken() {
  const meta = document.querySelector('meta[name="csrf-token"]');
  if (meta && meta.getAttribute('content')) {
    return meta.getAttribute('content');
  }
  const match = document.cookie.match(new RegExp('(^| )stylezone_csrf=([^;]+)'));
  return match ? decodeURIComponent(match[2]) : '';
}
window.getCsrfToken = getCsrfToken;

(function() {
  // 1. Theme Initialization & Persistence
  const savedTheme = localStorage.getItem('stylezone_theme') || 'dark';
  document.documentElement.setAttribute('data-theme', savedTheme);

  document.addEventListener('DOMContentLoaded', () => {
    // Theme toggle button logic
    const themeBtn = document.getElementById('theme-toggle-btn');
    if (themeBtn) {
      updateThemeIcon(savedTheme);
      themeBtn.addEventListener('click', () => {
        const currentTheme = document.documentElement.getAttribute('data-theme') || 'dark';
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
        document.documentElement.setAttribute('data-theme', newTheme);
        localStorage.setItem('stylezone_theme', newTheme);
        updateThemeIcon(newTheme);
      });
    }

    // Mobile Navigation Drawer Toggle
    const mobileToggle = document.getElementById('mobile-menu-toggle');
    const mobileDrawer = document.getElementById('mobile-drawer');
    if (mobileToggle && mobileDrawer) {
      mobileToggle.addEventListener('click', () => {
        mobileDrawer.classList.toggle('open');
        const isOpen = mobileDrawer.classList.contains('open');
        mobileToggle.setAttribute('aria-expanded', isOpen);
        mobileToggle.innerHTML = isOpen ? '✕' : '☰';
      });
    }

    // Modal Generic Dismissal
    document.querySelectorAll('[data-dismiss="modal"]').forEach(btn => {
      btn.addEventListener('click', () => {
        const modal = btn.closest('.modal');
        if (modal) modal.classList.remove('open');
      });
    });

    // Close modal on background click
    document.querySelectorAll('.modal').forEach(modal => {
      modal.addEventListener('click', (e) => {
        if (e.target === modal) modal.classList.remove('open');
      });
    });
  });

  function updateThemeIcon(theme) {
    const iconSpan = document.getElementById('theme-toggle-icon');
    if (!iconSpan) return;
    if (theme === 'light') {
      iconSpan.innerHTML = '🌙';
      iconSpan.setAttribute('title', 'Switch to Dark Mode');
    } else {
      iconSpan.innerHTML = '☀️';
      iconSpan.setAttribute('title', 'Switch to Light Mode');
    }
  }
})();
