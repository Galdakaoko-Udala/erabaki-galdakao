import TomSelect from "tom-select";

const initCensusZonesSelect = (input) => {
  // El input hidden original guarda los IDs separados por comas
  // Tom-select necesita un <select multiple> real, así que lo creamos
  const urlZones = input.dataset.urlZones || input.getAttribute("data-url-zones");
  const existingValues = input.value ? input.value.split(",").filter(Boolean) : [];

  // Crear el <select multiple> que sustituye al input hidden
  const select = document.createElement("select");
  select.multiple = true;
  select.name = input.name;
  select.id = input.id;
  // Copiar data-attributes relevantes
  [...input.attributes].forEach((attr) => {
    if (attr.name !== "type" && attr.name !== "value") {
      select.setAttribute(attr.name, attr.value);
    }
  });

  input.parentNode.insertBefore(select, input);
  input.remove();

  const ts = new TomSelect(select, {
    plugins: ["remove_button", "clear_button"],
    valueField: "id",
    labelField: "text",
    searchField: "text",
    maxOptions: 200,
    // No cargar nada al abrir si no hay query
    load(query, callback) {
      if (!query.length) return callback();
      const url = `${urlZones}?q=${encodeURIComponent(query)}`;
      fetch(url, {
        headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" }
      })
        .then((r) => r.json())
        .then((json) => {
          // Soporta { results: [{id, text}] } (formato select2) y array plano [{id,text}]
          const items = json.results || json;
          callback(items);
        })
        .catch(() => callback());
    },
    // Renderizado de opciones
    render: {
      option(data, escape) {
        return `<div>${escape(data.text)}</div>`;
      },
      item(data, escape) {
        return `<div>${escape(data.text)}</div>`;
      },
      no_results() {
        return `<div class="no-results">No se han encontrado resultados</div>`;
      }
    },
    onInitialize() {
      // Cargar los valores iniciales si los hay
      if (existingValues.length === 0) return;
      const url = `${urlZones}?ids=${existingValues.join(",")}`;
      fetch(url, {
        headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" }
      })
        .then((r) => r.json())
        .then((json) => {
          const items = json.results || json;
          items.forEach((item) => {
            this.addOption({ id: String(item.id), text: item.text });
            this.addItem(String(item.id), true); // true = silent, no dispara change
          });
          this.refreshItems();
        })
        .catch(() => {});
    }
  });

  return ts;
};

const SELECTOR =
  "input[name$='[authorization_handlers_options][census_authorization_handler][zones]']:not([disabled])";
const CHECKBOX_SELECTOR = "input[type=checkbox][id*='census_authorization_handler']";

const initAllSelects = () => {
  document.querySelectorAll(SELECTOR).forEach((input) => {
    // Evitar doble inicialización (tom-select añade ts-wrapper al padre)
    if (input.tomselect) return;
    // Si ya fue reemplazado por un <select> con tom-select inicializado, saltar
    if (input.tagName === "SELECT" && input.tomselect) return;
    initCensusZonesSelect(input);
  });
};

document.addEventListener("DOMContentLoaded", () => {
  initAllSelects();

  // Re-inicializar cuando se marca el checkbox de census_authorization_handler
  document.addEventListener("change", (e) => {
    if (e.target.matches(CHECKBOX_SELECTOR) && e.target.checked) {
      // Pequeño delay para que el DOM renderice los inputs asociados
      setTimeout(initAllSelects, 50);
    }
  });
});