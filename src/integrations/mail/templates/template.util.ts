export function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

export function linkTemplate(input: {
  heading: string;
  introduction: string;
  linkLabel: string;
  url: string;
  expiration: string;
}) {
  const heading = escapeHtml(input.heading);
  const introduction = escapeHtml(input.introduction);
  const url = escapeHtml(input.url);
  return {
    text: `${input.heading}\n\n${input.introduction}\n\n${input.url}\n\n${input.expiration}`,
    html: `<h1>${heading}</h1><p>${introduction}</p><p><a href="${url}">${escapeHtml(input.linkLabel)}</a></p><p>${escapeHtml(input.expiration)}</p>`,
  };
}

export function orderTemplate(input: {
  heading: string;
  orderNumber: string;
  status: string;
}) {
  const message = `Order ${input.orderNumber} is ${input.status}.`;
  return {
    text: `${input.heading}\n\n${message}`,
    html: `<h1>${escapeHtml(input.heading)}</h1><p>${escapeHtml(message)}</p>`,
  };
}
