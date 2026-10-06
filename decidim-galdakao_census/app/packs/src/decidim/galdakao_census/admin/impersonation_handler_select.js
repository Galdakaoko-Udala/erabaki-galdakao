// When going back to the impersonation form, the browser restores the selected authorization
// method without firing "change", so Decidim keeps showing (and submitting) the default handler
// form. Firing "change" again makes the visible form match the selected method.
const resyncHandlerSelect = () => {
  const select = document.getElementById("impersonate_user_authorization_handler_name");
  if (!select) {
    return;
  }

  select.dispatchEvent(new Event("change", { bubbles: true }));
};

window.addEventListener("pageshow", resyncHandlerSelect);
document.addEventListener("turbo:load", resyncHandlerSelect);
