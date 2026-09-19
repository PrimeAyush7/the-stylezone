/* ==========================================================================
   THE STYLEZONE - NON-TECHNICAL ADMIN PORTAL JAVASCRIPT
   ========================================================================== */

document.addEventListener('DOMContentLoaded', () => {
  // Edit Service Modal Populate
  document.querySelectorAll('.btn-edit-service').forEach(btn => {
    btn.addEventListener('click', () => {
      const id = btn.getAttribute('data-id');
      const name = btn.getAttribute('data-name');
      const price = btn.getAttribute('data-price');
      const duration = btn.getAttribute('data-duration');
      const desc = btn.getAttribute('data-desc');
      const active = btn.getAttribute('data-active');

      const modal = document.getElementById('edit-service-modal');
      const form = document.getElementById('edit-service-form');
      if (!modal || !form) return;

      form.action = `/admin/services/${id}/edit`;
      document.getElementById('edit-srv-name').value = name;
      document.getElementById('edit-srv-price').value = price;
      document.getElementById('edit-srv-duration').value = duration;
      document.getElementById('edit-srv-desc').value = desc || '';
      document.getElementById('edit-srv-active').value = active;

      modal.classList.add('open');
    });
  });

  // Block Slot Date Helper
  const blockDateInput = document.getElementById('block-date');
  if (blockDateInput && !blockDateInput.value) {
    const today = new Date().toISOString().split('T')[0];
    blockDateInput.value = today;
  }
});
