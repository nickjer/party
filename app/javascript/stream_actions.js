Turbo.StreamActions.reload = function () {
  this.targetElements.forEach((targetElement) => {
    targetElement.removeAttribute("disabled")
    targetElement.reload()
    targetElement.setAttribute("disabled", "")
  })
}
