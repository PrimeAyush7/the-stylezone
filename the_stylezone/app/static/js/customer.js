/* ==========================================================================
   THE STYLEZONE - CUSTOMER PORTAL & CANCELLATION HANDLERS
   ========================================================================== */

document.addEventListener('DOMContentLoaded', () => {
  const cancelModal = document.getElementById('cancel-appointment-modal');
  let activeBookingIdToCancel = null;

  document.querySelectorAll('.btn-cancel-appt').forEach(btn => {
    btn.addEventListener('click', () => {
      activeBookingIdToCancel = btn.getAttribute('data-booking-id');
      const srv = btn.getAttribute('data-service');
      const dt = btn.getAttribute('data-datetime');
      
      const modalInfo = document.getElementById('cancel-modal-info');
      if (modalInfo) {
        modalInfo.textContent = `Are you sure you want to cancel your appointment for ${srv} on ${dt}?`;
      }
      
      if (cancelModal) cancelModal.classList.add('open');
    });
  });

  const confirmCancelBtn = document.getElementById('btn-confirm-cancel');
  if (confirmCancelBtn) {
    confirmCancelBtn.addEventListener('click', async () => {
      if (!activeBookingIdToCancel) return;

      const reasonInput = document.getElementById('cancel-reason');
      const reason = reasonInput ? reasonInput.value.trim() : '';
      const csrfToken = window.getCsrfToken();

      confirmCancelBtn.disabled = true;
      confirmCancelBtn.textContent = 'Cancelling...';

      try {
        const resp = await fetch(`/account/api/appointments/${activeBookingIdToCancel}/cancel`, {
          method: 'POST',
          headers: { 
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken
          },
          body: JSON.stringify({ reason, csrf_token: csrfToken })
        });

        const res = await resp.json();
        if (!resp.ok) {
          throw new Error(res.detail || 'Cancellation failed.');
        }

        alert('Your appointment has been cancelled successfully.');
        window.location.reload();
      } catch (err) {
        alert(`Error: ${err.message}`);
        confirmCancelBtn.disabled = false;
        confirmCancelBtn.textContent = 'Confirm Cancellation';
      }
    });
  }
});
