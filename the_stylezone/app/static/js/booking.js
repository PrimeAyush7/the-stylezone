/* ==========================================================================
   THE STYLEZONE - 5-STEP REAL APPOINTMENT BOOKING WIZARD
   ========================================================================== */

document.addEventListener('DOMContentLoaded', () => {
  const wizard = document.getElementById('booking-wizard');
  if (!wizard) return;

  const state = {
    step: 1,
    serviceId: null,
    serviceName: '',
    servicePrice: 0,
    serviceDuration: 30,
    date: '',
    time: '',
    customerName: '',
    customerEmail: '',
    customerPhone: '',
    notes: ''
  };

  const initialServiceId = wizard.getAttribute('data-initial-service');
  if (initialServiceId) {
    const preCard = document.querySelector(`.service-select-card[data-id="${initialServiceId}"]`);
    if (preCard) selectService(preCard);
  }

  document.querySelectorAll('.service-select-card').forEach(card => {
    card.addEventListener('click', () => selectService(card));
  });

  function selectService(card) {
    document.querySelectorAll('.service-select-card').forEach(c => c.classList.remove('selected'));
    card.classList.add('selected');

    state.serviceId = parseInt(card.getAttribute('data-id'), 10);
    state.serviceName = card.getAttribute('data-name');
    state.servicePrice = parseFloat(card.getAttribute('data-price'));
    state.serviceDuration = parseInt(card.getAttribute('data-duration'), 10);

    const nextBtn = document.getElementById('btn-step1-next');
    if (nextBtn) nextBtn.disabled = false;
  }

  const dateInput = document.getElementById('booking-date');
  if (dateInput) {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    dateInput.min = `${yyyy}-${mm}-${dd}`;

    const maxDate = new Date();
    maxDate.setDate(maxDate.getDate() + 60);
    const maxY = maxDate.getFullYear();
    const maxM = String(maxDate.getMonth() + 1).padStart(2, '0');
    const maxD = String(maxDate.getDate()).padStart(2, '0');
    dateInput.max = `${maxY}-${maxM}-${maxD}`;

    dateInput.addEventListener('change', () => {
      state.date = dateInput.value;
      if (state.date) {
        loadAvailabilitySlots();
      }
    });
  }

  document.getElementById('btn-step1-next')?.addEventListener('click', () => goToStep(2));
  document.getElementById('btn-step2-prev')?.addEventListener('click', () => goToStep(1));
  document.getElementById('btn-step2-next')?.addEventListener('click', () => goToStep(3));
  document.getElementById('btn-step3-prev')?.addEventListener('click', () => goToStep(2));
  document.getElementById('btn-step3-next')?.addEventListener('click', () => goToStep(4));
  document.getElementById('btn-step4-prev')?.addEventListener('click', () => goToStep(3));
  document.getElementById('btn-step4-next')?.addEventListener('click', validateAndGoToReview);
  document.getElementById('btn-step5-prev')?.addEventListener('click', () => goToStep(4));
  document.getElementById('btn-confirm-booking')?.addEventListener('click', submitFinalBooking);

  function goToStep(stepNum) {
    state.step = stepNum;
    document.querySelectorAll('.wizard-step-content').forEach(s => s.classList.remove('active'));
    document.getElementById(`wizard-step-${stepNum}`)?.classList.add('active');

    for (let i = 1; i <= 5; i++) {
      const ind = document.getElementById(`step-ind-${i}`);
      if (!ind) continue;
      ind.classList.remove('active', 'completed');
      if (i < stepNum) ind.classList.add('completed');
      if (i === stepNum) ind.classList.add('active');
    }

    wizard.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  async function loadAvailabilitySlots() {
    const slotsContainer = document.getElementById('slots-container');
    const loadingEl = document.getElementById('slots-loading');
    const errorEl = document.getElementById('slots-error');
    const nextBtn = document.getElementById('btn-step3-next');

    slotsContainer.innerHTML = '';
    loadingEl.style.display = 'block';
    errorEl.style.display = 'none';
    if (nextBtn) nextBtn.disabled = true;

    try {
      const resp = await fetch(`/api/public/availability?date=${state.date}&service_id=${state.serviceId}`);
      const data = await resp.json();
      loadingEl.style.display = 'none';

      if (data.is_configured === false || (!data.available && data.message)) {
        errorEl.textContent = data.message || 'Booking is currently unavailable for this date.';
        errorEl.style.display = 'block';
        return;
      }

      if (!data.slots || data.slots.length === 0) {
        errorEl.textContent = 'No available time slots found for this date. Please choose another date.';
        errorEl.style.display = 'block';
        return;
      }

      data.slots.forEach(slot => {
        const pill = document.createElement('button');
        pill.type = 'button';
        pill.className = `slot-pill ${slot.available ? '' : 'unavailable'}`;
        pill.textContent = slot.time;
        
        if (slot.available) {
          pill.addEventListener('click', () => {
            document.querySelectorAll('.slot-pill').forEach(p => p.classList.remove('selected'));
            pill.classList.add('selected');
            state.time = slot.time;
            if (nextBtn) nextBtn.disabled = false;
          });
        } else {
          pill.title = slot.reason || 'Slot not available';
        }

        slotsContainer.appendChild(pill);
      });

    } catch (err) {
      loadingEl.style.display = 'none';
      errorEl.textContent = 'Unable to check slot availability. Please verify connection and retry.';
      errorEl.style.display = 'block';
    }
  }

  function validateAndGoToReview() {
    const nameInput = document.getElementById('cust-name');
    const emailInput = document.getElementById('cust-email');
    const phoneInput = document.getElementById('cust-phone');
    const notesInput = document.getElementById('cust-notes');

    const name = nameInput ? nameInput.value.trim() : '';
    const email = emailInput ? emailInput.value.trim().toLowerCase() : '';
    const phone = phoneInput ? phoneInput.value.trim() : '';
    const notes = notesInput ? notesInput.value.trim() : '';

    if (!name || name.length < 2) {
      alert('Please enter your full name.');
      nameInput?.focus();
      return;
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email || !emailRegex.test(email)) {
      alert('Please enter a valid email address.');
      emailInput?.focus();
      return;
    }

    state.customerName = name;
    state.customerEmail = email;
    state.customerPhone = phone;
    state.notes = notes;

    document.getElementById('rec-service-name').textContent = state.serviceName;
    document.getElementById('rec-duration').textContent = `${state.serviceDuration} Mins`;
    document.getElementById('rec-date').textContent = state.date;
    document.getElementById('rec-time').textContent = state.time;
    document.getElementById('rec-cust-name').textContent = state.customerName;
    document.getElementById('rec-cust-email').textContent = state.customerEmail;
    document.getElementById('rec-cust-phone').textContent = state.customerPhone || 'Not provided';
    document.getElementById('rec-notes').textContent = state.notes || 'None';
    document.getElementById('rec-total-price').textContent = `₹${state.servicePrice.toFixed(0)}`;

    goToStep(5);
  }

  async function submitFinalBooking() {
    const confirmBtn = document.getElementById('btn-confirm-booking');
    const submitError = document.getElementById('submit-booking-error');

    confirmBtn.disabled = true;
    confirmBtn.innerHTML = 'Securing Appointment...';
    submitError.style.display = 'none';

    const csrfToken = window.getCsrfToken();

    try {
      const resp = await fetch('/api/bookings/create', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({
          service_id: state.serviceId,
          appointment_date: state.date,
          start_time: state.time,
          name: state.customerName,
          email: state.customerEmail,
          phone: state.customerPhone,
          notes: state.notes,
          csrf_token: csrfToken
        })
      });

      const result = await resp.json();

      if (!resp.ok) {
        throw new Error(result.detail || 'Could not complete appointment booking.');
      }

      window.location.href = result.redirect_url;

    } catch (err) {
      confirmBtn.disabled = false;
      confirmBtn.innerHTML = 'Confirm Appointment';
      submitError.textContent = err.message;
      submitError.style.display = 'block';
    }
  }
});
