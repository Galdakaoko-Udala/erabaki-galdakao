// resource_permissions_multiselect.js.es6
// Reemplaza el input de calles en la configuración de permisos de componentes
// por un select2 multi con búsqueda Ajax contra /admin/galdakao/streets

// = require select2
// = require_self

$(() => {
  const url_streets = "/admin/galdakao/streets";

  /**
   * Convierte un input de texto (IDs separados por coma) en un select2 múltiple.
   * Carga los textos de las calles seleccionadas vía Ajax.
   */
  const select2InputTags = (queryStr) => {
    const $input = $(queryStr);

    const $select = $('<select class="' + $input.attr("class") + '" style="width:100%" multiple="multiple"><select>');

    if ($input.val() !== "") {
      const values = $input.val().split(",");
      values.forEach((item) => {
        $select.append('<option value="' + item + '" selected="selected">' + item + "</option>");
      });

      // Cargar los textos reales vía Ajax
      $.get(url_streets, { ids: values }, (data) => {
        $select.val("");
        $select.contents("option").remove();
        data.forEach((item) => {
          $select.append(new Option(item.text, item.id, true, true));
        });
        $select.trigger("change");
      }, "json");
    }

    $select.insertAfter($input);
    $input.hide();

    $select.change(() => {
      $input.val($select.val().join(","));
    });

    return $select;
  };

  // Aplica el select2 al campo de calles en los permisos de recursos
  $("input[name$='[authorization_handlers_options][census_authorization_handler][streets]'").each((idx, input) => {
    select2InputTags(input).select2({
      ajax: {
        url: url_streets,
        delay: 100,
        dataType: "json",
        processResults: (data) => {
          return {
            results: data
          };
        }
      },
      multiple: true,
      theme: "foundation"
    });
  });
});
