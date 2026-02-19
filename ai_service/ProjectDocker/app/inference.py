import torch
from torchvision import models
import torch.nn as nn
from app.preprocessing_tools.dataset_tool import augmentDataPath, SingleFolderDataset
from app.test_model import showAndTestImages, generateOutputImages
from app.preprocess_data import getTransforms
    
def inference(model, image, device):
    model.eval()
    with torch.no_grad():
        image = image.to(device)
        values = model(image)
        _, predicted = torch.max(values, 1)
    return values, predicted
    


def testInference(test_dataset, model, device, classNames):
    class_counts = {label: [0] * len(classNames) for _, label, _ in test_dataset}
    
    print('Inference on test dataset')
    for i in range(len(test_dataset)):
        image, label, _ = test_dataset[i]
        values, predicted = inference(model, image.unsqueeze(0), device)
        class_counts[label][predicted.item()] += 1

    for class_label, predictionCount in class_counts.items():
        print(f'\nClass {test_dataset.classes[class_label]}:')
        for i in range(len(classNames)):
            print(f'  {classNames[i]}: {predictionCount[i]}')

    return class_counts


def loadDevice(forceCpu=False):
    if torch.cuda.is_available() and not forceCpu:
        device = torch.device('cuda')
    else:
        device = torch.device('cpu')
    return device

def loadModel(modelPath, classSize, device):
    model = models.resnet18()
    model.fc = nn.Linear(model.fc.in_features, classSize)
    model_dict = torch.load(modelPath, weights_only=False)
    model.load_state_dict(model_dict['model'])
    model.to(device)
    return model

def inferenceData(classNames, modelPath, datasetPath, width, height, mean, std, slidingWindowSize, stride, outputFolder):
    classSize = len(classNames)
    device = loadDevice(forceCpu=False)
    model = loadModel(modelPath, classSize, device)
    model.eval()
    # datasetPath = augmentDataPath(datasetPath, datasetPath, 100000, width, height, [rotation.identity])
    test_dataset = SingleFolderDataset(
        datasetPath,
        transform=getTransforms(width, height, True, mean, std)
    )
    testInference(test_dataset, model, device, classNames)    
    # generateOutputImages(test_dataset, model, device, classNames, outputFolder, slidingWindowSize, stride)
    showAndTestImages(test_dataset, model, device, classNames, slidingWindowSize, stride)


def inference1vsAll(models, image, device, swapIndex):
    values = torch.zeros((len(models), 2))
    for i, model in enumerate(models):
        values[i], _ = inference(model, image, device)
        if i >= swapIndex:
            values[i][0], values[i][1] = values[i][1], values[i][0]
    
    # Se tutti i valori sono negativi, allora la predizione è -1 (fuori distribuzione)
    if torch.all(values[:, 0] < 0):
        predicted = torch.tensor(-1)
    else:
        predicted = torch.argmax(values[:, 0]) # Altrimenti si prende il valore più alto
    # print(values)
    # print(predicted)
    return values, predicted
    

# Testa il modello 1 vs All
# models: lista di modelli
# test_dataset: dataset di test
# device: dispositivo su cui eseguire l'inference
# classNames: nomi delle classi
# swapIndex: indice a partire dal quale invertire i valori delle attribuzioni, è necessario invertirli ad un certo punto perché ImageFolder carica le classi in ordine alfabetico
# di conseguenza la classe Others (fuori distribuzione) potrebbe non essere sempre la seconda, nel nostro caso attuale, la classe Others è la penultima
# quindi swapIndex = len(classNames) - 2
def testInference1vsAll(models, test_dataset, device, classNames):
    swapIndex = len(classNames) - 2
    class_counts = {label: [0] * (len(classNames) + 1) for _, label, _ in test_dataset} # +1 per contare le immagini fuori distribuzione

    print('Inference on test dataset')
    for i in range(len(test_dataset)):
        image, label, path = test_dataset[i]
        print(path)
        values, predicted = inference1vsAll(models, image.unsqueeze(0), device, swapIndex)
        class_counts[label][predicted.item()] += 1        


    for class_label, predictionCount in class_counts.items():
        print(f'\nClass {test_dataset.classes[class_label]}:')
        for i in range(len(classNames)):
            print(f'  {classNames[i]}: {predictionCount[i]}')
        print(f'  Other: {predictionCount[-1]}')


    return class_counts