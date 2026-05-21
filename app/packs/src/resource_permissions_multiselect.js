import $ from "jquery";
import select2 from "select2";
select2(window, $);

$(() => {
  const url_zones = "/admin/galdakao/zones";
  const select2InputTags = ($input) => {
    const $select = $('<select style="width:100%" multiple="multiple"></select>');
    if ($input.val() !== "") {
      const values = $input.val().split(",");
      $.get(url_zones, { ids: values }, (data) => {
        data.forEach((item) => {
          $select.append(new Option(item.text, item.id, true, true));
        });
        $select.trigger("change");
      }, "json");
    }
    $select.insertAfter($input);
    $input.hide();
    $select.change(() => {
      $input.val($select.val() ? $select.val().join(",") : "");
    });
    return $select;
  };
  const initSelect2 = ($input) => {
    if ($input.data("select2-initialized")) return;
    $input.data("select2-initialized", true);
    const $select = select2InputTags($input);
    $select.select2({
      ajax: {
        url: url_zones,
        delay: 100,
        dataType: "json",
        processResults: (data) => ({ results: data })
      },
      multiple: true,
      theme: "default"
    });
  };
  $("input[name$='[authorization_handlers_options][census_authorization_handler][zones]']:not([disabled])").each((idx, input) => {
    initSelect2($(input));
  });
  $(document).on("change", "input[type=checkbox][id*='census_authorization_handler']", function() {
    if (this.checked) {
      const $zonesInput = $(this).closest(".row.column")
        .find("input[name$='[authorization_handlers_options][census_authorization_handler][zones]']");
      if ($zonesInput.length) {
        initSelect2($zonesInput);
      }
    }
  });
  $(document).on("select2:open", function() {
    setTimeout(function() {
      const sf = document.activeElement;
      if (sf && sf.classList.contains("select2-search__field")) {
        if (parseFloat(sf.style.width) < 10) {
          sf.style.width = "150px";
        }
      }
    }, 0);
  });
});
