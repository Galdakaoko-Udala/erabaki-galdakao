import TomSelect from "tom-select";

const URL_ZONES = "/admin/galdakao/zones";

const SELECTOR = "select[id*='authorization_handlers_options'][id*='zones']";
const CHECKBOX_SELECTOR = "input[type=checkbox][id*='census_authorization_handler']";

const initCensusZonesSelect = (select) => {
  if (select.tomselect) return; // ya inicializado

  // Valores iniciales que ya tiene el select de Rails
  const existingValues = [...select.options].map((o) => o.value).filter(Boolean);

  new TomSelect(select, {
    plugins: ["remove_button", "clear_button"],
    valueField: "id",
    labelField: "text",
    searchField: "text",
    maxOptions: 200,
    load(query, callback) {
      if (!query.length) return callback();
      fetch(`${URL_ZONES}?q=${encodeURIComponent(query)}`, {
        headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" }
      })
        .then((r) => r.json())
        .then((json) => callback(json.results || json))
        .catch(() => callback());
    },
    render: {
      option: (data, escape) => `<div>${escape(data.text)}</div>`,
      item:   (data, escape) => `<div>${escape(data.text)}</div>`,
      no_results: () => `<div class="no-results">No se han encontrado resultados</div>`
    },
    onInitialize() {
      if (existingValues.length === 0) return;
      fetch(`${URL_ZONES}?ids=${existingValues.join(",")}`, {
        headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" }
      })
        .then((r) => r.json())
        .then((json) => {
          const items = json.results || json;
          items.forEach((item) => {
            this.addOption({ id: String(item.id), text: item.text });
            this.addItem(String(item.id), true);
          });
          this.refreshItems();
        })
        .catch(() => {});
    }
  });
};

const initAllSelects = () => {
  document.querySelectorAll(SELECTOR).forEach(initCensusZonesSelect);
};

document.addEventListener("DOMContentLoaded", () => {
  initAllSelects();

  document.addEventListener("change", (e) => {
    if (e.target.matches(CHECKBOX_SELECTOR) && e.target.checked) {
      setTimeout(initAllSelects, 50);
    }
  });
});