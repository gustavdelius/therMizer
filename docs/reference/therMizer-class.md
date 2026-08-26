# therMizer marker classes

S4 marker subclasses of \`MizerParams\` and \`MizerSim\` that enable the
S3 dispatch used by the \`projectEncounter()\`, \`projectPredRate()\`
and \`projectEReproAndGrowth()\` methods defined in this package. They
add no slots and are created by mizer when the package is loaded, not by
a \`setClass()\` call here, so that therMizer can be chained with other
mizer extension packages in either load order.
