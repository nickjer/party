Turbo.StreamActions.reload = function () {
  this.targetElements.forEach((targetElement) => {
    if (targetElement.src) {
      targetElement.disabled = false
      targetElement.reload()
      targetElement.disabled = true
    } else if (targetElement.dataset.src) {
      targetElement.src = targetElement.dataset.src
    }
  })
}
