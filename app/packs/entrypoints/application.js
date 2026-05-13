/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/packs and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

// Activate Active Storage
// import * as ActiveStorage from "@rails/activestorage"
// ActiveStorage.start()
//
// Select2 y multiselect de calles (Galdakao)
import $ from "jquery";
window.jQuery = $;
window.$ = $;
import "../src/select2.js";
import "../stylesheets/select2.css";
import "../stylesheets/select2-foundation-theme.css";
import "../src/resource_permissions_multiselect.js";
