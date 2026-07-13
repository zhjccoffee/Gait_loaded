import vtk

reader = vtk.vtkXMLPolyDataReader()
reader.SetFileName("hat_ribs_scap.vtp")
reader.Update()

writer = vtk.vtkSTLWriter()
writer.SetFileName("hat_ribs_scap.stl")
writer.SetInputData(reader.GetOutput())
writer.Write()