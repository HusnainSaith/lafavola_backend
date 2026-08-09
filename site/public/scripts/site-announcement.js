const announcement = document.querySelector('#site-announcement');

if (announcement instanceof HTMLDialogElement) {
  const close = () => announcement.close();
  const closeButton = announcement.querySelector('.site-announcement__close');
  const dismissButton = announcement.querySelector('.site-announcement__dismiss');

  announcement.showModal();
  closeButton?.focus();
  closeButton?.addEventListener('click', close);
  dismissButton?.addEventListener('click', close);
  announcement.addEventListener('click', (event) => {
    if (event.target === announcement) close();
  });
}
