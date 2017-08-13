{ CompositeDisposable } = require 'atom'
relative = require 'relative'
nativeImage = require('electron').nativeImage

generateNativeImageTag = (relativePath, fullPath, fileName, textEditor) ->
    img = nativeImage.createFromPath(fullPath)
    width = img.getSize().width
    height = img.getSize().height
    textEditor.insertText '<img src="' + relativePath + '" width="' + width + '" height="' + height + '" alt="' + fileName + '">\n'



generateTag = (fileExtension, extension, relativePath, fileName, textEditor) ->
    type = undefined
    if fileExtension != extension and extension != 'img'
        textEditor.insertText '<!-- Converted from ' + fileExtension + ' -->\n'
    textEditor.insertText type = {
        'js': '<script src="' + relativePath.replace(fileExtension, extension) + '"></script>\n'
        'css': '<link href="' + relativePath.replace(fileExtension, extension) + '" rel="stylesheet">\n'
        'img': '<img src="' + relativePath + '" alt="' + fileName + '">\n'
    }[extension]
    return

intOrExtDrag = (currentPathFileExtension, fileExtension, relativePath, fileName, textEditor, selectedFiles, currentPath) ->

    scriptArray = ['js', 'jsx', 'coffee']
    linkArray = ['css', 'scss', 'less']
    imageArray = ['apng', 'ico' ,'gif' ,'svg' ,'bmp' ,'webp']
    nativeImageArray = ['jpg', 'jpeg', 'png', 'ico']


    count = 0
    while count < selectedFiles.length
      selected = selectedFiles[count].file?.path || selectedFiles[count].path
      if currentPathFileExtension.toString() == 'html'
          if scriptArray.includes(fileExtension)
              generateTag fileExtension, 'js', relative(currentPath, selected), fileName, textEditor
          if linkArray.includes(fileExtension)
              generateTag fileExtension, 'css', relative(currentPath, selected), fileName, textEditor
          if imageArray.includes(fileExtension)
              generateTag fileExtension, 'img', relative(currentPath, selected), fileName, textEditor
          if nativeImageArray.includes(fileExtension)
              generateNativeImageTag relative(currentPath, selected), selected, fileName, textEditor
      else
        textEditor.insertText "'#{relative currentPath, selected}'" + '\n'
      count++
    return

module.exports = activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.workspace.observeTextEditors((textEditor) ->
        textEditorElement = atom.views.getView(textEditor)
        textEditorElement.addEventListener 'drop', (e) ->
            relativePath = undefined
            if e.dataTransfer.files.length
                files = e.dataTransfer.files
                i = 0
                while i < files.length
                    file = files[i]
                    f = file.name
                    if f.indexOf(".") == -1
                      return
                    else
                      currentPath = textEditor.buffer.file.path
                      unless typeof currentPath isnt "undefined" then return
                      currentPathFileExtension = currentPath.split('.').pop()
                      extFileExtension = file.path.split('.').pop()
                      relativize = atom.project.relativizePath(file.path)
                      relativePath = relative(currentPath, relativize[1])
                      fileName = relativePath.split('/').slice(-1).join().split('.').shift()
                      e.preventDefault()
                      e.stopPropagation()
                      intOrExtDrag currentPathFileExtension, extFileExtension, relativePath, fileName, textEditor, files, currentPath
                      i++
            else
                selectedFiles = document.querySelectorAll('.file.entry.list-item.selected')
                selectedSpan = document.querySelector('.file.entry.list-item.selected>span')
                if selectedFiles and selectedSpan # check if a file is dropped
                  dragPath = selectedSpan.dataset.path
                  currentPath = textEditor.buffer.file.path
                  unless typeof currentPath isnt "undefined" then return
                  currentPathFileExtension = currentPath.split('.').pop()
                  relativePath = relative(currentPath, dragPath)
                  fileName = relativePath.split('/').slice(-1).join().split('.').shift()
                  intFileExtension = relativePath.split('.').pop()
                  intOrExtDrag currentPathFileExtension, intFileExtension, relativePath, fileName, textEditor, selectedFiles, currentPath
            return
    )
    return

deactivate: ->
    @subscriptions.dispose()
