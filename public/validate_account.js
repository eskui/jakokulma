function strippedAccountNumber(e) {
  return e = e.replace(/ /g, ""), e.replace(/\./g, "")
}

//========== For development ==============
function ibanOnFocusOut() {
  // console.log(country)
  accountNumberComplete = strippedAccountNumber($("#iban_number").val())
  var e = accountNumberComplete.substring(0, 3);
  var n = accountNumberComplete.substring(3);
  var t = CalcIBAN(CountryData('SE'), e, n);
  console.log(t)
  $("#acc_number").val(t)
}

//========= For Production ================
// function ibanOnFocusOut() {
//     if (accountNumberComplete = strippedAccountNumber($("#iban_number").val()), validateAccountNumber(accountNumberComplete)) {
//         var e = accountNumberComplete.substring(0, 4),
//             n = accountNumberComplete.substring(4),
//             t = CalcIBAN(CountryData("NO"), e, n);
//         $("#acc_number").val(t), $("input[name=commit]").attr("disabled", !1), $("input[name=commit]").attr("class", "button"), $("input[name=commit]").val("Lagre"), $("#account_error").remove()
//     } else $("input[name=commit]").attr("disabled", !0), $("input[name=commit]").attr("class", "error"), $("input[name=commit]").val("Kan ikke lagre. Angi et gyldig kontonummer."), $("#account_error").length || $('<label for="iban_number" generated="true" class="error" id="account_error">Ugyldig kontonummer.</label>').insertAfter($("#iban_number"))
// }

function showRows() {
  $("a.see-more-row").fadeOut(), $("a.see-more-row").hide(), $("div#filters div.row").css("display", "block")
}

function insertAfter(e, n) {
  n.parentNode.insertBefore(e, n.nextSibling)
}

var mod11OfNumberWithControlDigit = function(e) {
  var n, t = 2,
      r = 0;
  for (n = e.length - 2; n >= 0; --n) r += e.charAt(n) * t, ++t > 7 && (t = 2);
  var o = 11 - r % 11;
  return 11 === o ? 0 : o
},

validateAccountNumber = function(e) {
  return e ? (e = e.toString().replace(/ /g, ""), e = e.toString().replace(/\./g, ""), 11 !== e.length ? !1 : parseInt(e.charAt(e.length - 1), 10) === mod11OfNumberWithControlDigit(e)) : !1
};