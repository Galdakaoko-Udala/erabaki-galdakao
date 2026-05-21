import TomSelect from "tom-select";

const URL_ZONES = "/admin/galdakao/zones";

const SELECTOR = "input[id*='authorization_handlers_options'][id*='zones']";
const CHECKBOX_SELECTOR = "input[type=checkbox][id*='census_authorization_handler']";

const initCensusZonesSelect = (input) => {
  if (input.dataset.tsInitialized) return;
  input.dataset.tsInitialized = "1";

  const existingValues = input.value ? input.value.split(",").filter(Boolean) : [];

  const select = document.createElement("select");
  select.multiple = true;
  select.name = input.name;
  select.id = input.id + "_ts";
  // Marcar el select para no reinicializarlo
  select.dataset.tsInitialized = "1";

  input.type = "hidden";
  input.parentNode.insertBefore(select, input.nextSibling);

  const ts = new TomSelect(select, {
    plugins: ["remove_button", "clear_button"],
    valueField: "id",
    labelField: "text",
    searchField: "text",
    preload: true,
    maxOptions: 200,
    load(query, callback) {
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
    },
    onChange(values) {
      input.value = values.join(",");
    }
  });

  return ts;
};

const initAllSelects = (openAfter = false) => {
  document.querySelectorAll(SELECTOR).forEach((input) => {
    // Saltar inputs ya procesados (ahora hidden con dataset marcado)
    if (input.dataset.tsInitialized) return;
    // Saltar también si ya existe un select _ts hermano
    const existingSelect = input.parentNode.querySelector(`#${input.id}_ts`);
    if (existingSelect) return;

    const ts = initCensusZonesSelect(input);
    if (openAfter && ts) {
      setTimeout(() => ts.open(), 100);
    }
  });
};

document.addEventListener("DOMContentLoaded", () => {
  initAllSelects(false);

  document.addEventListener("change", (e) => {
    if (e.target.matches(CHECKBOX_SELECTOR) && e.target.checked) {
      setTimeout(() => initAllSelects(true), 50);
    }
  });
});