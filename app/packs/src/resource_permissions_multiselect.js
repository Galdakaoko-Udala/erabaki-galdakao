import TomSelect from "tom-select";

const URL_ZONES = "/admin/galdakao/zones";

const INPUT_SELECTOR = "input[id*='authorization_handlers_options'][id*='zones']";
const CHECKBOX_SELECTOR = "input[type=checkbox][id*='census_authorization_handler']";

const initCensusZonesSelect = (input) => {
  if (input.dataset.tomInitialized) return; // ya inicializado
  input.dataset.tomInitialized = "true";

  // Ocultamos el input original
  input.style.display = "none";

  // Creamos un <select multiple> justo después
  const select = document.createElement("select");
  select.multiple = true;
  select.style.width = "100%";
  input.insertAdjacentElement("afterend", select);

  // Valores iniciales desde el input oculto (IDs separados por coma)
  const existingValues = input.value ? input.value.split(",").map((v) => v.trim()).filter(Boolean) : [];

  const ts = new TomSelect(select, {
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
    onChange(values) {
      // Sincroniza los IDs seleccionados de vuelta al input oculto
      input.value = Array.isArray(values) ? values.join(",") : values;
    },
    onInitialize() {
      if (existingValues.length === 0) return;
      // Carga los textos reales de los IDs ya guardados
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
  document.querySelectorAll(INPUT_SELECTOR).forEach(initCensusZonesSelect);
};

document.addEventListener("DOMContentLoaded", () => {
  initAllSelects();

  document.addEventListener("change", (e) => {
    if (e.target.matches(CHECKBOX_SELECTOR) && e.target.checked) {
      setTimeout(initAllSelects, 50);
    }
  });
});