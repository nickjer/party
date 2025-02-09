Turbo.StreamActions.reload = function () {
  this.targetElements.forEach((targetElement) => {
    if (targetElement.dataset.src) {
      targetElement.src = targetElement.dataset.src
      targetElement.src = null
    }
  })
}
