# Launcher for Julia 1.11; on 1.12+ `julia -m ZolaPreprocessor` works directly.
using ZolaPreprocessor

exit(ZolaPreprocessor.main(ARGS))
