// Shows the numbers range field only when the selected constraint needs a range
const RANGE_CONSTRAINTS = ["only_range", "except_range"];

document.addEventListener("turbo:load", () => {
  const select = document.getElementById("zone_street_numbers_constraint");
  const field = document.getElementById("numbers_range_field");
  if (!select || !field) {
    return;
  }

  const toggle = () => {
    field.classList.toggle("hidden", !RANGE_CONSTRAINTS.includes(select.value));
  };

  select.addEventListener("change", toggle);
  toggle();
});
