Turbo.StreamActions.reload = function () {
  this.targetElements.forEach((targetElement) => {
    if (targetElement.src) {
      targetElement.reload()
    } else if (targetElement.dataset.src) {
      targetElement.src = targetElement.dataset.src
    }
  })
}
