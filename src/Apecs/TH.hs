{-# LANGUAGE TemplateHaskell #-}

module Apecs.TH
  ( makeWorld, makeWorldNoEC
  )where

import Language.Haskell.TH

import Apecs.Util (EntityCounter)

genName :: String -> Q Name
genName s = mkName . show <$> newName s

-- | Same as 'makeWorld', but has no 'EntityCounter'
makeWorldNoEC :: String -> [Name] -> Q [Dec]
makeWorldNoEC worldName cTypes = do
  cTypesNames <- mapM (\t -> do rec <- genName "rec"; return (ConT t, rec)) cTypes

  let wld = mkName worldName
      has = mkName "Has"
      sys = mkName "System"
      wldDecl = DataD [] wld [] Nothing [RecC wld records] []

      makeRecord (t,n) = (n, Bang NoSourceUnpackedness SourceStrict, ConT (mkName "Storage") `AppT` t)
      records = makeRecord <$> cTypesNames

      makeInstance (t,n) =
        InstanceD Nothing [] ((ConT has `AppT` ConT wld) `AppT` t)
          [ FunD (mkName "getStore") [Clause []
              (NormalB$ ConE sys `AppE` (VarE (mkName "asks") `AppE` VarE n))
            [] ]
          ]

      initDecl = FunD (mkName $ "init" ++ worldName) [Clause []
        (NormalB$ iterate (\wE -> AppE (AppE (VarE $ mkName "<*>") wE) (VarE $ mkName "initStore")) (AppE (VarE $ mkName "return") (ConE wld)) !! length records)
        [] ]

      hasDecl = makeInstance <$> cTypesNames

  return $ wldDecl : initDecl : hasDecl

{-|

> makeWorld "WorldName" [''Component1, ''Component2, ...]

turns into

> data WorldName = WorldName ...
> instance WorldName `Has` Component1 where ...
> instance WorldName `Has` Component2 where ...
> ...
>
> instance WorldName `Has` EntityCounter where ...
>
> initWorldName :: IO WorldName
> initWorldName = WorldName <$> initStore <*> ...

|-}
makeWorld :: String -> [Name] -> Q [Dec]
makeWorld worldName cTypes = makeWorldNoEC worldName (cTypes ++ [''EntityCounter])

