"use strict";(self.webpackChunkapp=self.webpackChunkapp||[]).push([[1936],{73140:function(t,e,n){function r(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(t);e&&(r=r.filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable}))),n.push.apply(n,r)}return n}function o(t){for(var e=1;e<arguments.length;e++){var n=null!=arguments[e]?arguments[e]:{};e%2?r(Object(n),!0).forEach((function(e){i(t,e,n[e])})):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):r(Object(n)).forEach((function(e){Object.defineProperty(t,e,Object.getOwnPropertyDescriptor(n,e))}))}return t}function i(t,e,n){return(e=c(e))in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function a(t){return a="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(t){return typeof t}:function(t){return t&&"function"==typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},a(t)}function l(t,e){for(var n=0;n<e.length;n++){var r=e[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(t,c(r.key),r)}}function c(t){var e=function(t,e){if("object"!==a(t)||null===t)return t;var n=t[Symbol.toPrimitive];if(void 0!==n){var r=n.call(t,e||"default");if("object"!==a(r))return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===e?String:Number)(t)}(t,"string");return"symbol"===a(e)?e:String(e)}n.d(e,{Z:function(){return s}});var s=function(){function t(){!function(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}(this,t),this.config={}}var e,n,r;return e=t,n=[{key:"set",value:function(t){var e=arguments.length>1&&void 0!==arguments[1]?arguments[1]:null;"object"===a(t)?this.config=o(o({},this.config),t):this.config[t]=e}},{key:"get",value:function(t){return this.config[t]}}],n&&l(e.prototype,n),r&&l(e,r),Object.defineProperty(e,"prototype",{writable:!1}),t}()},28814:function(t,e,n){var r=n(23972),o=n.n(r);function i(t){return i="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(t){return typeof t}:function(t){return t&&"function"==typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},i(t)}function a(t,e){for(var n=0;n<e.length;n++){var r=e[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(t,(o=r.key,a=void 0,a=function(t,e){if("object"!==i(t)||null===t)return t;var n=t[Symbol.toPrimitive];if(void 0!==n){var r=n.call(t,e||"default");if("object"!==i(r))return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===e?String:Number)(t)}(o,"string"),"symbol"===i(a)?a:String(a)),r)}var o,a}var l=null,c=function(){function t(e){!function(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}(this,t),this.$modal=$(l),this.$source=e,this.$content=$(".confirm-modal-content",this.$modal),this.$buttonConfirm=$("[data-confirm-ok]",this.$modal),this.$buttonCancel=$("[data-confirm-cancel]",this.$modal);var n="confirm-modal-title-".concat(Math.random().toString(36).substring(7));this.$modal.removeAttr("id"),$("#confirm-modal-title",this.$modal).attr("id",n),this.$modal.attr("aria-labelledby",n),$("body").append(this.$modal),this.$modal.foundation()}var e,n,r;return e=t,(n=[{key:"confirm",value:function(t){var e=this;return this.$content.html(t),this.$buttonConfirm.off("click"),this.$buttonCancel.off("click"),new Promise((function(t){e.$buttonConfirm.on("click",(function(n){n.preventDefault(),e.$modal.foundation("close"),t(!0),e.$source.focus()})),e.$buttonCancel.on("click",(function(n){n.preventDefault(),e.$modal.foundation("close"),t(!1),e.$source.focus()})),e.$modal.foundation("open").on("closed.zf.reveal",(function(){e.$modal.remove()}))}))}}])&&a(e.prototype,n),r&&a(e,r),Object.defineProperty(e,"prototype",{writable:!1}),t}(),s=function(t,e){(function(t,e){var n=$(e).data("confirm");return!n||!!o().fire(e,"confirm")&&(null===l&&(l=$("#confirm-modal")[0].outerHTML,$("#confirm-modal").remove()),new c($(e)).confirm(n).then((function(n){var r=o().fire(e,"confirm:complete",[n]);if(n&&r)if($(e).data("confirm",null),$(e).removeAttr("data-confirm"),"click"===t.type&&($(e).is('button[type="submit"]')||$(e).is('input[type="submit"]')))$(e).parents("form").submit();else{var i=t.originalEvent||t,a=i;"function"===typeof Event&&(a=new i.constructor(i.type,i)),t.target.dispatchEvent(a)}})),!1)})(t,e)||o().stopEverything(t)},u=function(t,e){for(var n=t.target;n instanceof Element&&!o().matches(n,e);)n=n.parentNode;return n instanceof Element?n:null},d=function(t,e){return e.some((function(e){var n=u(t,e);return null!==n&&(s(t,n),!0)}))};document.addEventListener("click",(function(t){return d(t,[o().linkClickSelector,o().buttonClickSelector,o().formInputClickSelector])})),document.addEventListener("change",(function(t){return d(t,[o().inputChangeSelector])})),document.addEventListener("submit",(function(t){return d(t,[o().formSubmitSelector])})),document.addEventListener("DOMContentLoaded",(function(){$(o().formInputClickSelector).on("click.confirm",(function(t){s(t,u(t,o().formInputClickSelector))}))}))},76189:function(t,e,n){var r=n(79292);function o(t){return o="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(t){return typeof t}:function(t){return t&&"function"==typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},o(t)}function i(t,e){return function(t){if(Array.isArray(t))return t}(t)||function(t,e){var n=null==t?null:"undefined"!=typeof Symbol&&t[Symbol.iterator]||t["@@iterator"];if(null!=n){var r,o,i,a,l=[],c=!0,s=!1;try{if(i=(n=n.call(t)).next,0===e){if(Object(n)!==n)return;c=!1}else for(;!(c=(r=i.call(n)).done)&&(l.push(r.value),l.length!==e);c=!0);}catch(t){s=!0,o=t}finally{try{if(!c&&null!=n.return&&(a=n.return(),Object(a)!==a))return}finally{if(s)throw o}}return l}}(t,e)||function(t,e){if(!t)return;if("string"===typeof t)return a(t,e);var n=Object.prototype.toString.call(t).slice(8,-1);"Object"===n&&t.constructor&&(n=t.constructor.name);if("Map"===n||"Set"===n)return Array.from(t);if("Arguments"===n||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n))return a(t,e)}(t,e)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function a(t,e){(null==e||e>t.length)&&(e=t.length);for(var n=0,r=new Array(e);n<e;n++)r[n]=t[n];return r}function l(t,e){for(var n=0;n<e.length;n++){var r=e[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(t,(i=r.key,a=void 0,a=function(t,e){if("object"!==o(t)||null===t)return t;var n=t[Symbol.toPrimitive];if(void 0!==n){var r=n.call(t,e||"default");if("object"!==o(r))return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===e?String:Number)(t)}(i,"string"),"symbol"===o(a)?a:String(a)),r)}var i,a}var c=function(){function t(e,n,o){!function(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}(this,t),this.modal=e,this.uploadItem=n,this.progressBar=n.querySelector(".progress-bar"),this.validationSent=!1,this.fileTooBig=!1,e.options.maxFileSize&&o.file.size>e.options.maxFileSize?(this.fileTooBig=!0,this.showError([e.locales.file_size_too_large])):this.upload=new r.DirectUpload(o.file,o.url,this)}var e,n,o;return e=t,(n=[{key:"showError",value:function(t){this.progressBar.classList.add("filled"),this.progressBar.innerHTML=this.modal.locales.validation_error,this.uploadItem.dataset.state="error";var e=this.uploadItem.querySelector(".upload-errors");t.forEach((function(t){var n=document.createElement("li");n.classList.add("form-error","is-visible"),n.innerHTML=t,e.appendChild(n)}))}},{key:"validate",value:function(t){var e=this;if(!this.validationSent){var n=this.modal.options.addAttribute;this.modal.options.titled&&(n="file");var r=this.modal.input.dataset.uploadValidationsUrl,o=new URLSearchParams({resourceClass:this.modal.options.resourceClass,property:n,blob:t,formClass:this.modal.options.formObjectClass});fetch("".concat(r,"?").concat(o),{method:"POST",headers:{"Content-Type":"application/json","X-CSRF-Token":$("meta[name=csrf-token]").attr("content")}}).then((function(t){return t.json()})).then((function(t){!function(t){for(var n=[],r=0,o=Object.entries(t);r<o.length;r++){var a=i(o[r],2)[1];n=n.concat(a)}e.progressBar.style.justifyContent="center",0===n.length?(e.progressBar.innerHTML=e.modal.locales.uploaded,e.uploadItem.dataset.state="validated"):e.showError(n),e.progressBar.classList.add("filled")}(t)})),this.validationSent=!0}}},{key:"directUploadWillStoreFileWithXHR",value:function(t){var e=this;t.upload.addEventListener("progress",(function(t){var n=Math.floor(t.loaded/t.total*100),r="15%";n>15&&(r="".concat(n,"%")),e.progressBar.style.width=r,e.progressBar.innerHTML=100!==n?"".concat(n,"%"):e.modal.locales.validating}))}}])&&l(e.prototype,n),o&&l(e,o),Object.defineProperty(e,"prototype",{writable:!1}),t}(),s=function(t){var e=arguments.length>1&&void 0!==arguments[1]?arguments[1]:31;if(t.length<=e)return t;var n=Math.floor(e/2)-3,r=e-n-3;return"".concat(t.slice(0,n),"...").concat(t.slice(-r))},u=function(t,e,n){var r=document.createElement("input");return r.type="hidden",t&&(r.className="string"===typeof t?t:t.join(" ")),e&&(r.name=e),n&&(r.value=n),r},d=function(t){if(!t)return"";var e=document.createElement("div");return e.appendChild(document.createTextNode(t)),e.innerHTML};function f(t){return f="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(t){return typeof t}:function(t){return t&&"function"==typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},f(t)}function p(t,e){for(var n=0;n<e.length;n++){var r=e[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(t,(o=r.key,i=void 0,i=function(t,e){if("object"!==f(t)||null===t)return t;var n=t[Symbol.toPrimitive];if(void 0!==n){var r=n.call(t,e||"default");if("object"!==f(r))return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===e?String:Number)(t)}(o,"string"),"symbol"===f(i)?i:String(i)),r)}var o,i}var m=function(){function t(e){var n=arguments.length>1&&void 0!==arguments[1]?arguments[1]:{};!function(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}(this,t),this.button=e;var r={};try{r=JSON.parse(e.dataset.upload)}catch(o){}this.options=Object.assign(r,n),this.name=this.button.name,this.modal=document.querySelector("#".concat(e.dataset.open)),this.saveButton=this.modal.querySelector("button.add-file-".concat(this.name)),this.attachmentCounter=0,this.dropZoneEnabled=!0,this.modalTitle=this.modal.querySelector(".reveal__title"),this.uploadItems=this.modal.querySelector(".upload-items"),this.locales=JSON.parse(this.uploadItems.dataset.locales),this.dropZone=this.modal.querySelector(".dropzone"),this.input=this.dropZone.querySelector("input"),this.uploadContainer=document.querySelector(".upload-container-for-".concat(this.name)),this.activeAttachments=this.uploadContainer.querySelector(".active-uploads"),this.trashCan=this.createTrashCan()}var e,n,r;return e=t,(n=[{key:"uploadFile",value:function(t){var e=this;if(this.dropZoneEnabled){var n=t.name.split(".")[0].slice(0,31),r=this.createUploadItem(t.name,n,"init"),o=new c(this,r,{file:t,url:this.input.dataset.directUploadUrl,attachmentName:t.name});o.fileTooBig||(o.upload.create((function(i,a){if(i){r.dataset.state="error";var l=r.querySelector(".progress-bar");l.classList.add("filled"),l.innerHTML=e.locales.error,console.error(i)}else{var c=e.getOrdinalNumber(),s=document.createElement("div");s.classList.add("attachment-details"),s.dataset.fileid=r.dataset.fileid,s.dataset.filename=t.name;var f=document.createElement("span");f.style.display="none",s.appendChild(f);var p=u(null,null,a.signed_id);if(e.options.titled?p.name="".concat(e.options.resourceName,"[").concat(e.options.addAttribute,"][").concat(c,"][file]"):p.name="".concat(e.options.resourceName,"[").concat(e.options.addAttribute,"]"),e.options.titled){var m=u("hidden-title","".concat(e.options.resourceName,"[").concat(e.options.addAttribute,"][").concat(c,"][title]"),n);f.innerHTML=d("".concat(n," (").concat(t.name,")")),s.appendChild(m)}else f.innerHTML=d(t.name);e.options.multiple||e.cleanTrashCan(),s.appendChild(p),r.appendChild(s),o.validate(a.signed_id)}})),this.updateDropZone())}}},{key:"getOrdinalNumber",value:function(){var t=this.attachmentCounter;return this.attachmentCounter+=1,t}},{key:"updateDropZone",value:function(){this.options.multiple||(this.uploadItems.children.length>0?(this.dropZone.classList.add("disabled"),this.dropZoneEnabled=!1,this.input.disabled=!0):(this.dropZone.classList.remove("disabled"),this.dropZoneEnabled=!0,this.input.disabled=!1))}},{key:"createUploadItem",value:function(t,e,n){var r,o=this,i=document.createElement("div");i.classList.add("upload-item"),i.setAttribute("data-fileid",Math.random().toString(36).substring(7)),i.setAttribute("data-filename",t);var a=document.createElement("div"),l=document.createElement("div"),c=document.createElement("div");a.classList.add("row","upload-item-first-row"),l.classList.add("row","upload-item-second-row"),c.classList.add("row","upload-item-third-row");var u=document.createElement("span"),f=["columns","file-name-span"];this.options.titled?f.push("small-4","medium-5"):f.push("small-12"),(r=u.classList).add.apply(r,f),u.innerHTML=d(s(t));var p=document.createElement("div");p.classList.add("progress-bar"),n&&("validated"===n?p.innerHTML=this.locales.uploaded:(p.innerHTML="0%",p.style.width="15%"),i.dataset.state=n);var m=document.createElement("div");m.classList.add("progress-bar-border"),m.appendChild(p);var h=document.createElement("div");h.classList.add("columns","progress-bar-wrapper"),h.appendChild(m),this.options.titled?h.classList.add("small-4","medium-5"):h.classList.add("small-10");var v=document.createElement("ul");v.classList.add("upload-errors");var y=document.createElement("button");y.classList.add("columns","small-3","medium-2","remove-upload-item"),y.innerHTML="&times; ".concat(this.locales.remove),y.addEventListener("click",(function(t){t.preventDefault(),o.trashCan.append(i),o.updateDropZone()}));var b=document.createElement("span");b.classList.add("columns","small-5","title-and-filename-span"),b.innerHTML=d("".concat(e," (").concat(s(t),")")),a.appendChild(u),l.appendChild(h),c.appendChild(v);var g=null;if(this.options.titled){var S=document.createElement("input");S.classList.add("attachment-title"),S.type="text",S.value=e,S.addEventListener("input",(function(t){var e,n,r;t.preventDefault(),e=o.uploadItems,n=o.saveButton,r=!0,Array.from(e.children).forEach((function(t){var e=t.querySelector("input[type='text']").value,o=t.querySelector(".no-title-error");e&&0!==e.length?o.classList.remove("is-visible"):(r=!1,n.disabled=!0,o.classList.add("is-visible"),t.appendChild(o))})),r&&(n.disabled=!1)})),(g=document.createElement("div")).classList.add("columns","small-5","title-input-container"),g.appendChild(S);var E=document.createElement("span");E.classList.add("form-error","no-title-error"),E.role="alert",E.innerHTML=this.locales.title_required,g.appendChild(E);var w=document.createElement("span");w.classList.add("title-label-span"),w.innerHTML=this.locales.title;var C=document.createElement("div");C.classList.add("columns","small-8","medium-7","title-container"),C.appendChild(w),a.appendChild(C),l.appendChild(g)}return l.appendChild(y),i.appendChild(a),i.appendChild(l),i.appendChild(c),this.uploadItems.appendChild(i),i}},{key:"updateAddAttachmentsButton",value:function(){0===this.activeAttachments.children.length?this.button.innerHTML=this.modalTitle.dataset.addlabel:this.button.innerHTML=this.modalTitle.dataset.editlabel}},{key:"createTrashCan",value:function(){var t=document.createElement("div");return t.classList.add("trash-can"),t.style.display="none",this.uploadItems.parentElement.appendChild(t),t}},{key:"cleanTrashCan",value:function(){var t=this;Array.from(this.trashCan.children).forEach((function(e){var n=e.dataset.fileid,r=t.activeAttachments.querySelector("div[data-fileid='".concat(n,"']"));r&&r.remove(),e.remove()}))}}])&&p(e.prototype,n),r&&p(e,r),Object.defineProperty(e,"prototype",{writable:!1}),t}();document.addEventListener("DOMContentLoaded",(function(){document.querySelectorAll("button.add-file").forEach((function(t){var e=new m(t);!function(t){Array.from(t.activeAttachments.children).forEach((function(e){var n=t.createUploadItem(e.dataset.filename,e.dataset.title,"validated");e.dataset.fileid=n.dataset.fileid}))}(e),function(t){t.input.addEventListener("change",(function(e){e.preventDefault();var n=e.target.files;Array.from(n).forEach((function(e){return t.uploadFile(e)}))}))}(e),function(t){t.button.addEventListener("click",(function(e){e.preventDefault(),Array.from(t.trashCan.children).forEach((function(e){t.uploadItems.append(e)})),0===t.uploadItems.children.length?t.modalTitle.innerHTML=t.modalTitle.dataset.addlabel:t.modalTitle.innerHTML=t.modalTitle.dataset.editlabel,t.updateDropZone()}))}(e),function(t){t.dropZone.addEventListener("dragenter",(function(t){t.preventDefault()})),t.dropZone.addEventListener("dragover",(function(e){e.preventDefault(),t.dropZone.classList.add("is-dragover")})),t.dropZone.addEventListener("dragleave",(function(){t.dropZone.classList.remove("is-dragover")})),t.dropZone.addEventListener("drop",(function(e){e.preventDefault();var n=e.dataTransfer.files;Array.from(n).forEach((function(e){return t.uploadFile(e)}))}))}(e),function(t){t.saveButton.addEventListener("click",(function(e){e.preventDefault();var n=t.uploadItems.querySelectorAll(".upload-item[data-state='validated']"),r=n.length;if(n.forEach((function(e){var n=e.querySelector(".attachment-details");n?t.activeAttachments.appendChild(n):n=t.activeAttachments.querySelector(".attachment-details[data-fileid='".concat(e.dataset.fileid,"'"));var r=n.querySelector("span");if(r.classList.add("filename"),t.options.titled){var o=e.querySelector("input[type='text']").value;n.dataset.title=o;var i=n.querySelector(".hidden-title");if(i)i.value=o;else{var a=n.querySelector("[name='".concat(t.options.resourceName,"[").concat(t.name,"][]'")).value,l=t.getOrdinalNumber(),c=u("hidden-title","".concat(t.options.resourceName,"[").concat(t.options.addAttribute,"][").concat(l,"][title]"),o),f=u("hidden-id","".concat(t.options.resourceName,"[").concat(t.options.addAttribute,"][").concat(l,"][id]"),a);n.appendChild(c),n.appendChild(f)}r.innerHTML="".concat(d(o)," (").concat(d(s(e.dataset.filename)),")")}else r.innerHTML=d(s(e.dataset.filename,19));r.style.display="block"})),!t.options.titled&&t.trashCan.children.length>0&&(t.activeAttachments.innerHTML="<input name='".concat(t.options.resourceName,"[remove_").concat(t.name,']\' type="hidden" value="true">')),r>0){var o=$(t.uploadContainer.querySelector("input[type='checkbox']"));o&&(o.prop("checked",!0),o.trigger("change"))}t.cleanTrashCan(),t.updateAddAttachmentsButton()}))}(e)}))}))},88673:function(t,e,n){n.d(e,{Z:function(){return l}});var r=n(73377);n(76096),n(23401),n(68788);function o(t){return function(t){if(Array.isArray(t))return i(t)}(t)||function(t){if("undefined"!==typeof Symbol&&null!=t[Symbol.iterator]||null!=t["@@iterator"])return Array.from(t)}(t)||function(t,e){if(!t)return;if("string"===typeof t)return i(t,e);var n=Object.prototype.toString.call(t).slice(8,-1);"Object"===n&&t.constructor&&(n=t.constructor.name);if("Map"===n||"Set"===n)return Array.from(t);if("Arguments"===n||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n))return i(t,e)}(t)||function(){throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function i(t,e){(null==e||e>t.length)&&(e=t.length);for(var n=0,r=new Array(e);n<e;n++)r[n]=t[n];return r}var a=["bold","italic","link","underline","header","list","alt","break","width","style","code","blockquote","indent"];function l(t){var e=$(t).data("toolbar"),n=$(t).data("disabled"),i=[["bold","italic","underline","linebreak"],[{list:"ordered"},{list:"bullet"}],["link","clean"],["code","blockquote"],[{indent:"-1"},{indent:"+1"}]],l=!1,c=!1;"content"===e?i=[[{header:[2,3,4,5,6,!1]}]].concat(o(i)):"full"===e&&(l=!0,c=!0,i=[[{header:[2,3,4,5,6,!1]}]].concat(o(i),[["video"],["image"]]));var s={linebreak:{},toolbar:{container:i,handlers:{linebreak:r.Z}}},u=$(t).siblings('input[type="hidden"]');t.innerHTML=u.val()||"";var d=$('meta[name="csrf-token"]').attr("content");if(c&&a.push("video"),l){a.push("image"),s.imageResize={modules:["Resize","DisplaySize"]},s.imageUpload={url:$(t).data("uploadImagesPath"),method:"POST",name:"image",withCredentials:!1,headers:{"X-CSRF-Token":d},callbackOK:function(t,e){$("div.ql-toolbar").last().removeClass("editor-loading"),e(t.url)},callbackKO:function(t){$("div.ql-toolbar").last().removeClass("editor-loading"),console.log("Image upload error: ".concat(t.message))},checkBeforeSend:function(t,e){$("div.ql-toolbar").last().addClass("editor-loading"),e(t)}};var f=$(t).data("dragAndDropHelpText");$(t).after('<p class="help-text" style="margin-top:-1.5rem;">'.concat(f,"</p>"))}var p=new Quill(t,{modules:s,formats:a,theme:"snow"});return!1===l&&p.root.addEventListener("drop",(function(t){return t.preventDefault()})),n&&p.disable(),p.on("text-change",(function(){var e=p.getText(),n=new CustomEvent("quill-position",{detail:p.getSelection()});if(t.dispatchEvent(n),"\n"!==e&&"\n\n"!==e||0!==p.root.querySelectorAll("iframe").length){var r="<p><br></p>",o=p.root.innerHTML.replace(new RegExp("^".concat(r,"|").concat(r,"$"),"g"),"");u.val(o)}else u.val("")})),p.emitter.emit("editor-ready"),p}},73377:function(t,e,n){n.d(e,{Z:function(){return L}});var r=n(30457),o=n(20642),i=n(43052),a=n(8671);function l(t){return l="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(t){return typeof t}:function(t){return t&&"function"==typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},l(t)}function c(t){return function(t){if(Array.isArray(t))return s(t)}(t)||function(t){if("undefined"!==typeof Symbol&&null!=t[Symbol.iterator]||null!=t["@@iterator"])return Array.from(t)}(t)||function(t,e){if(!t)return;if("string"===typeof t)return s(t,e);var n=Object.prototype.toString.call(t).slice(8,-1);"Object"===n&&t.constructor&&(n=t.constructor.name);if("Map"===n||"Set"===n)return Array.from(t);if("Arguments"===n||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n))return s(t,e)}(t)||function(){throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function s(t,e){(null==e||e>t.length)&&(e=t.length);for(var n=0,r=new Array(e);n<e;n++)r[n]=t[n];return r}function u(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}function d(t,e){for(var n=0;n<e.length;n++){var r=e[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(t,(o=r.key,i=void 0,i=function(t,e){if("object"!==l(t)||null===t)return t;var n=t[Symbol.toPrimitive];if(void 0!==n){var r=n.call(t,e||"default");if("object"!==l(r))return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===e?String:Number)(t)}(o,"string"),"symbol"===l(i)?i:String(i)),r)}var o,i}function f(t,e,n){return e&&d(t.prototype,e),n&&d(t,n),Object.defineProperty(t,"prototype",{writable:!1}),t}function p(t,e){if("function"!==typeof e&&null!==e)throw new TypeError("Super expression must either be null or a function");t.prototype=Object.create(e&&e.prototype,{constructor:{value:t,writable:!0,configurable:!0}}),Object.defineProperty(t,"prototype",{writable:!1}),e&&m(t,e)}function m(t,e){return m=Object.setPrototypeOf?Object.setPrototypeOf.bind():function(t,e){return t.__proto__=e,t},m(t,e)}function h(t){var e=function(){if("undefined"===typeof Reflect||!Reflect.construct)return!1;if(Reflect.construct.sham)return!1;if("function"===typeof Proxy)return!0;try{return Boolean.prototype.valueOf.call(Reflect.construct(Boolean,[],(function(){}))),!0}catch(t){return!1}}();return function(){var n,r=v(t);if(e){var o=v(this).constructor;n=Reflect.construct(r,arguments,o)}else n=r.apply(this,arguments);return function(t,e){if(e&&("object"===l(e)||"function"===typeof e))return e;if(void 0!==e)throw new TypeError("Derived constructors may only return object or undefined");return function(t){if(void 0===t)throw new ReferenceError("this hasn't been initialised - super() hasn't been called");return t}(t)}(this,n)}}function v(t){return v=Object.setPrototypeOf?Object.getPrototypeOf.bind():function(t){return t.__proto__||Object.getPrototypeOf(t)},v(t)}Quill.debug("error");var y=Quill.import("delta"),b=Quill.import("blots/break"),g=Quill.import("blots/embed"),S=Quill.import("blots/scroll"),E=Quill.import("parchment");Quill.register({"modules/history":a.Z},!0),Quill.import("ui/icons").linebreak="\u23ce";var w=function(t){p(n,t);var e=h(n);function n(){return u(this,n),e.apply(this,arguments)}return f(n,[{key:"length",value:function(){return 1}},{key:"value",value:function(){return"\n"}},{key:"insertInto",value:function(t,e){Reflect.apply(g.prototype.insertInto,this,[t,e])}}]),n}(b);Quill.register(w);var C=function(t){p(n,t);var e=h(n);function n(){return u(this,n),e.apply(this,arguments)}return f(n,[{key:"optimize",value:function(){var t=arguments.length>0&&void 0!==arguments[0]?arguments[0]:[],e=arguments.length>1&&void 0!==arguments[1]?arguments[1]:{};!0!==this.batch&&(this.parchmentOptimize(t,e),t.length>0&&this.emitter.emit("scroll-optimize",t,e))}},{key:"parchmentOptimize",value:function(){var t=this,e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:[],n=arguments.length>1&&void 0!==arguments[1]?arguments[1]:{};Reflect.apply(E.Container.prototype.optimize,this,[n]);for(var r=c(this.observer.takeRecords());r.length>0;)e.push(r.pop());for(var o=function e(n,r){n&&n!==t&&n.domNode.parentNode&&(n.domNode.__blot&&null===n.domNode.__blot.mutations&&(n.domNode.__blot.mutations=[]),r&&e(n.parent))},i=function t(e){e.domNode.__blot&&(e instanceof E.Container&&e.children.forEach(t),e.optimize(n))},a=e,l=0;a.length>0;l+=1){if(l>=100)throw new Error("[Parchment] Maximum optimize iterations reached");for(a.forEach((function(t){var e=E.find(t.target,!0);e&&(e.domNode===t.target&&("childList"===t.type?(o(E.find(t.previousSibling,!1)),t.addedNodes.forEach((function(t){var e=E.find(t,!1);o(e,!1),e instanceof E.Container&&e.children.forEach((function(t){o(t,!1)}))}))):"attributes"===t.type&&o(e.prev)),o(e))})),this.children.forEach(i),r=(a=c(this.observer.takeRecords())).slice();r.length>0;)e.push(r.pop())}}}]),n}(S);function L(t){var e=t.selection.getRange()[0],n=t.getLeaf(e.index)[0],r=t.getLeaf(e.index+1)[0],o=t.getText(e.index-1,1);if(null===r||n.parent!==r.parent)t.insertEmbed(e.index,"break",!0,"user"),t.insertEmbed(e.index,"break",!0,"user");else if("\n"===o){var i=(new y).retain(e.index).insert("\n");t.updateContents(i,Quill.sources.USER)}else t.insertEmbed(e.index,"break",!0,"user");t.setSelection(e.index+1,Quill.sources.SILENT)}Quill.register("blots/scroll",C,!0),E.register(C),Quill.register("modules/linebreak",(function(t){t.getModule("toolbar").addHandler("linebreak",(function(){L(t)})),t.emitter.on("editor-ready",(function(){var e=t.getLength();"\n\n"===t.getText(e-2,2)&&t.deleteText(t.getLength()-2,2)})),(0,r.Z)(t),(0,o.Z)(t),(0,i.Z)(t)}))},43657:function(t,e,n){n(72665);$((function(){$(".js-tags-container").tagsinput({tagClass:"input__tag",trimValue:!0})}))}}]);
//# sourceMappingURL=1936-dc0baac2204eee890ee8.js.map